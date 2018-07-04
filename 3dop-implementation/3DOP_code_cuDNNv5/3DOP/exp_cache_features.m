function exp_cache_features(trainset, category)
% cache features for SSVM training

% category = 'car';
% trainset = 'train';

if exist('category', 'var')
    % class-dependent proposals
    cfg = kitti_config(category, trainset);
    model = loadModel(category, trainset);
else
    % class-independent proposals
    cfg = kitti_config_generic(trainset);
    model = loadModel_generic(trainset);
end
db = db_from_kitti(kitti_dir, trainset);
db = dbFilter(db, cfg.category, 3);
nimages = length(db.impos);

% main loop
parfor i = 1 : nimages
    tic_toc_print('%d / %d\n', i, nimages);
    id = db.impos(i).im;   

    % inference
    cache_features(id, model, db.impos(i), cfg);
end
