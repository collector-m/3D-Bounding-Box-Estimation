function priorModel = computePrior(category, split)
% compute prior parameters

cfg = kitti_config(category, split);

folder = 'data/models';
mkdir_if_missing(folder);
prior_file = sprintf('%s/%s_prior_%s.mat', folder, cfg.category, split);
if exist(prior_file, 'file')
    priorModel = load(prior_file);
    return;
end

disp('compute prior parameters...');
db = db_from_kitti(kitti_dir, split);
db = dbFilter(db, cfg.category, 3);

% get number of images for this dataset
nimages = length(db.impos);

% main loop
pointDists = cell(nimages, 1);
layoutDists = cell(nimages, 1);
for i = 1 : nimages
    close all;
    tic_toc_print('%d / %d\n', i, nimages);
    id = db.impos(i).im;

    camdata = getCamData(cfg.calib_dir, id);
    % road extimation 
    % compute depth from disparity
    disparity = computeDisparity(id, cfg);
    xyz = depthFromDisparity(disparity, camdata);
    % road extimation 
    plane = computeRoadPlane(id, disparity, camdata, xyz, cfg);
    
    % compute 3D boxes
    objects = db.impos(i);
    boxes = cell(0);
    xyzs = [xyz'; ones(1, size(xyz,1))];
    in_boxes = false(1, size(xyz,1));
    for k = 1 : length(objects.types)
        ry = objects.ry(k);
        t = objects.t(k,:);
        sizes = objects.sizes3D(k,:);

        % compute rotational matrix around yaw axis
        R = [+cos(ry), 0, +sin(ry);
             0,        1,        0;
             -sin(ry), 0, +cos(ry)];

        % 3D bounding box dimensions
        l = sizes(1);
        h = sizes(2);
        w = sizes(3);

        % 3D bounding box corners
        x_corners = [l/2, l/2, -l/2, -l/2, l/2, l/2, -l/2, -l/2];
        y_corners = [0,0,0,0,-h,-h,-h,-h];
        z_corners = [w/2, -w/2, -w/2, w/2, w/2, -w/2, -w/2, w/2];

        % rotate and translate 3D bounding box
        corners_3D = R * [x_corners; y_corners; z_corners];
        corners_3D = bsxfun(@plus, corners_3D, t(:));

        nx = corners_3D(:,1) - corners_3D(:,4);
        nx = nx' ./ norm(nx);
        planeX = [nx, -nx * corners_3D(:, 1); nx, -nx * corners_3D(:, 4)];

        ny = corners_3D(:,1) - corners_3D(:,5);
        ny = ny' ./ norm(ny);
        planeY = [ny, -ny * corners_3D(:, 1); ny, -ny * corners_3D(:, 5)];

        nz = corners_3D(:,1) - corners_3D(:,2);
        nz = nz' ./ norm(nz);
        planeZ = [nz, -nz * corners_3D(:, 1); nz, -nz * corners_3D(:, 2)];

        boxes{k}.planeX = planeX;
        boxes{k}.planeY = planeY;
        boxes{k}.planeZ = planeZ;

        % color points in 3D boxes
        dx = planeX * xyzs;
        dy = planeY * xyzs;
        dz = planeZ * xyzs;
        in_box = (prod(dx) <= 0) & (prod(dy) <= 0) & (prod(dz) <= 0);
        in_boxes = in_boxes | in_box;
    end

    % distance of points inside bounding boxes to the ground plane
    if any(in_boxes)
        xyzs = xyz(in_boxes, :);
        dist = [xyzs, ones(size(xyzs,1), 1)] * plane(:);
        pointDists{i} = dist;
    end           
    
    % distance of bounding boxes to the ground plane
    layoutDists{i} = [db.impos(i).t, ones(size(db.impos(i).t,1), 1)] * plane(:);
end

% MLE estimates
d = cat(1, pointDists{:});
d = d(d >= -0.5);
[heightMean, heightSigma] = normfit(d);

% MLE estimates
d = cat(1, layoutDists{:});
[dist2RoadMean, dist2RoadSigma] = normfit(d);

% distance of bounding boxes to the camera
ts = cat(1, db.impos.t);
dist2Cam = sqrt(sum(ts.^2, 2));
maxScope = max(dist2Cam) + 2;

% compute cuboid templates
template_cuboids = clusterPrototypes(db, cfg.category);

% save sampling prior
params.heightMean = heightMean;
params.heightSigma = heightSigma;
params.dist2RoadMean = dist2RoadMean;  
params.dist2RoadSigma = dist2RoadSigma;
params.dist2RoadExt = [dist2RoadMean-dist2RoadSigma, dist2RoadMean+dist2RoadSigma];
params.maxScope = maxScope;
save(prior_file, 'params', 'template_cuboids');

priorModel.params = params;
priorModel.template_cuboids = template_cuboids;