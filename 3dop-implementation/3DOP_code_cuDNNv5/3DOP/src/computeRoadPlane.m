function [ plane ] = computeRoadPlane(id, disparity, camdata, xyz, cfg)

plane_file = sprintf('%s/%s.txt', cfg.plane_dir, id);
try
    fid = fopen(plane_file);
    for ii = 1 : 3
        fgetl(fid);
    end
    fdata = textscan(fid, '%f %f %f %f');
    fclose(fid);
    assert(length(fdata{1}) == 1, 'plane file incorrect');
    plane = cat(2, fdata{:})';
    if plane(2) > 0
        plane = -plane;
    end
    plane = plane ./ norm(plane(1:3));
catch
    if strcmp(cfg.plane_mode, 'fast')
        C = camdata.P_left;
        intrinsics = [C(1,1), C(2,2), C(1,3), C(2,3), camdata.baseline];
        [R, Tr_cam_plane, Tr_plane] = computeRoadPlaneTransformation(single(disparity), intrinsics);

        [y, x] = find(R == 1);
        ind_floor = find(R == 1);
        ind = find(y >= intrinsics(4));
        pt3 = xyz(ind_floor(ind), :);

        if size(pt3,1) > 3
            pt3 = pt3(randperm(size(pt3,1), min(size(pt3,1), 100)), :);
            [plane, P, inliers] = ransacfitplane(pt3', 0.05, 0);
            % make sure the normal of road plane is facing up
            if plane(2) > 0
                plane = -plane;
            end
            plane = plane ./ norm(plane(1:3));
        else
            % go with the ground plane prior if road estimation fails
            plane = [0; -1; 0; 1.65];
        end
    elseif strcmp(cfg.plane_mode, 'robust')
        try
            load(sprintf('%s/%s.mat', cfg.roadmask_dir, id));
            if plane.normal(2) > 0
                % make sure the normal is always facing up
                plane.normal = -plane.normal;
            end
            plane = [plane.normal, -plane.point * plane.normal'];
            plane = plane ./ norm(plane(1:3));
        catch
            error('For robust ground plane estimation, please follow ./external/roadNet/roadDemo.m to compute road plane first.\n');
        end
    end

    savemat2txt(plane(:)', plane_file);
end
end