function exp_compute_proposals(trainset, testset, category)
% compute proposals for KITTI dataset

% category = 'car';
% trainset = 'train';
% testset = 'val';

if exist('category', 'var')
    % class-dependent proposals
    cfg = kitti_config(category, testset);
    model = loadModel(category, trainset);
else
    % class-independent proposals
    cfg = kitti_config_generic(testset);
    model = loadModel_generic(trainset);
end
image_ids = cfg.image_ids;

nimages = length(image_ids);
dirname = cfg.method.candidate_dir;

% main loop
parfor i = 1 : nimages
    tic_toc_print('%d / %d\n', i, nimages);
    id = image_ids{i};

    matfile = fullfile(dirname, id(1:4), sprintf('%s.mat', id));
    if exist(matfile, 'file')        
        continue;    
    end
    
    camdata = getCamData(cfg.calib_dir, id);
    im=imread(sprintf('%s/%s.png', cfg.image_dir, id));
    im_size = size(im);
    % compute depth from disparity
    disparity = computeDisparity(id, cfg);
    xyz = depthFromDisparity(disparity, camdata);
    % road extimation 
    plane = computeRoadPlane(id, disparity, camdata, xyz, cfg);

    % inference
    [boxes2D, scores, boxes3D] = boxes_infer(xyz, plane, ...
                                camdata, model, im_size, 0);

    save_candidates_mat(dirname, id, boxes2D, scores, boxes3D);
end



