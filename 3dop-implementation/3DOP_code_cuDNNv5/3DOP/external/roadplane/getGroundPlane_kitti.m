function getGroundPlane_kitti(video_ind)

dataset_globals;
if ~exist(ROADPLANE_PATH, 'dir')
    mkdir(ROADPLANE_PATH);
end;
info = getData('info');
if nargin < 1
    video_ind = [1 : length(info.videoname)]';
end;

for ii = 1 : length(video_ind)
    i = video_ind(ii);
    videoname = info.videoname{i};
    fprintf('video: %s\n', videoname);
    outfile = fullfile(ROADPLANE_PATH, [videoname '.mat']);
    planefile = fullfile(ROADPLANE_PATH, [videoname '_framedata.mat']);
    if exist([outfile ''], 'file')
        continue;
    end;
    
    if exist([planefile ''], 'file')
        load(planefile)
    else
        planedata = getFitData(info, i);
        save(planefile, 'planedata');
    end;
    
    %continue;
    [planedata, R, R_frame] = fewframefit(info, planedata, i, 6);
    save(outfile, 'planedata', 'R', 'R_frame')
end;



function planedata = getFitData(info, i)

n = info.numframes(i);
videonum = str2num(info.videoname{i});
planedata = struct('R', cell(n, 1), 'T_plane', cell(n, 1), 'Tr_cam_plane', cell(n, 1), 'plane', cell(n, 1), 'R_my', cell(n, 1));
    for j = 0 : info.numframes(i)-1     
        if mod(j,5)==0, fprintf('   frame: %d/%d\n', j+1, info.numframes(i)); end;
        stereodata = getData('3d', videonum, j);
        data = getData('calib', videonum);
        try
            gcdata = getData('gc', videonum, j);
            [y,x] = find(gcdata.gc_max == 1);
            [ind_floor] = find(gcdata.gc_max == 1);
            ind = find(y >= data.K_left(2, 3));
            x = x(ind);
            y = y(ind);
        catch
            fprintf('problem with GC file\n');
            x = []; y = [];
            ind_floor = [];
            ind = [];
        end;

        intrinsics = [data.K_left(1,1),data.K_left(2,2),data.K_left(1,3),data.K_left(2,3),data.baseline];
        if length(x) > 4000
            [R, Tr_cam_plane, T_plane] = computeRoadPlaneTransformation(single(stereodata.disparity),intrinsics, [x,y]);
        else
            [R, Tr_cam_plane, T_plane] = computeRoadPlaneTransformation(single(stereodata.disparity),intrinsics);
            [y, x] = find(R == 1);
            ind_floor = find(R == 1);
            ind = find(y >= data.K_left(2, 3));
        end;
        planedata(j+1).R = find(double(R));
        planedata(j+1).Tr_cam_plane = Tr_cam_plane;
        planedata(j+1).T_plane = T_plane;
        
        [plane, P, inliers] = ransacfitplane(stereodata.points3D(ind_floor(ind), :)', 0.06, 0);
        planedata(j+1).plane = plane;
        planedata(j+1).R_my = ind_floor(ind(inliers));
    end;
    
    
function [planedata, R, R_frame] = fewframefit(info, planedata_in, i, nframes)

imsize = info.imsize;
videonum = str2num(info.videoname{i});
odometrydata = getData('odometry', videonum);
Tr_total = odometrydata.Tr_total;
R = cell(info.numframes(i), 1);
R_frame = cell(info.numframes(i), 1);
n = info.numframes(i);
planedata = struct('T_plane', cell(n, 1), 'Tr_cam_plane', cell(n, 1), 'T_plane_frame', cell(n, 1), 'Tr_cam_plane_frame', cell(n, 1), ...
            'plane', cell(n, 1), 'plane_world', cell(n, 1));
camdata = getData('calib', videonum);
stereodataall = cell(n, 1);

for j = 0 : info.numframes(i) - 1
    if mod(j,5)==0, fprintf('   frame: %d/%d\n', j+1, info.numframes(i)); end;
    frame = j+1;
    points3d = [];
    frames = [];
    % project all points to current coordinate system
    for k = 1 : min(nframes, info.numframes(i) - j)
        if ~isempty(stereodataall{j+k})
            stereodata = stereodataall{j+k};
        else
            stereodata = getData('3d', videonum, j + k-1);
            stereodataall{j+k} = stereodata;
        end;
        points3d_k = stereodata.points3D(planedata_in(j + k).R, :);
        ind = find(~all(points3d_k == 0, 2));
        points3d_k = points3d_k(ind, :);
        T = inv(Tr_total{j+1}) * Tr_total{j+k};
        points3d_k = transformPointCloud(points3d_k, T);   % in the coord of the first frame
        points3d = [points3d; points3d_k]; 
        frames = [frames; k * ones(size(points3d_k, 1), 1)];
        if k==1
            stereodataall{j+1} = [];
        end;
    end;
    
    % get only points that are visible
    pts_2D = projectToImage(points3d', camdata.P_left);
    pts_2D = round(pts_2D');
    ind = find(min(pts_2D(:, 1:2), [], 2) >= 1 & pts_2D(:, 1) <=imsize(2) & pts_2D(:, 2) <=imsize(1));
    points3d = points3d(ind, :);
    frames = frames(ind, :);
    
    % fit plane
    [plane, P, inliers] = ransacfitplane(points3d', 0.15, 0);
    planedata(frame).plane = plane;
    n = plane(2:4);
    %p = [0, -plane(1) / plane(3), 0];
    p = projectPointToPlane([0,0,0],plane([2:4,1]));
    n = transformPointCloud([n, 0], Tr_total{frame}); 
    p = transformPointCloud(p, Tr_total{frame}); 
    d = -n*p';
    plane_world = [d, n] / n(2); %norm([n,d]);
    planedata(frame).plane_world = plane_world;
    planedata(frame).T_plane_frame = planedata_in(frame).T_plane;
    planedata(frame).Tr_cam_plane_frame = planedata_in(frame).Tr_cam_plane;
    planedata(frame).T_plane = roadPlaneToCameraTransformation(-plane(2:4) / plane(1));
    planedata(frame).Tr_cam_plane = inv(planedata(frame).T_plane);
    ind = find(frames(inliers) == 1);
    points3d_frame = points3d(inliers(ind), :);
    pts_2D = projectToImage(points3d_frame', camdata.P_left);
    pts_2D = round(pts_2D');
    ind = find(min(pts_2D(:, 1:2), [], 2) >= 1 & pts_2D(:, 1) <=imsize(2) & pts_2D(:, 2) <=imsize(1));
    ind = sub2ind(imsize(1:2), pts_2D(ind, 2), pts_2D(ind, 1));
    R_frame{frame} = ind;
    
    points3d = points3d(inliers, :);
    pts_2D = projectToImage(points3d', camdata.P_left);
    pts_2D = round(pts_2D');
    ind = find(min(pts_2D(:, 1:2), [], 2) >= 1 & pts_2D(:, 1) <=imsize(2) & pts_2D(:, 2) <=imsize(1));
    ind = sub2ind(imsize(1:2), pts_2D(ind, 2), pts_2D(ind, 1));
    R{frame} = ind;
end;
