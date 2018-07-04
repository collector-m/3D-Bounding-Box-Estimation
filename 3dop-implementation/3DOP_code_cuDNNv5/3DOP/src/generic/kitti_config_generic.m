function cfg = kitti_config_generic(data_split)

cfg = struct;
% data split: 'train', 'val', 'trainval' or 'test'
cfg.data_split = data_split;
cfg.category = [];

cfg.image_ids = data_ids(cfg.data_split);

% proposals configuration
cfg.method = props_config([], cfg.data_split, [], 'generic');

%% directories
% dataset directory
data_set = 'training';
if strcmp(cfg.data_split, 'test')
    data_set = 'testing';
end
cfg.data_set = data_set;
% folder for features caching
[~, cfg.cache_dir] = kitti_dir;
cfg.feat_dir = sprintf('%s-generic/features/%s', cfg.cache_dir, cfg.data_split);
mkdir_if_missing(cfg.feat_dir);

% get sub-directories
cam = 2; % 2 = left color camera
cfg.image_dir = fullfile(kitti_dir,['/object/' data_set '/image_' num2str(cam)]);
cfg.label_dir = fullfile(kitti_dir,['/object/' data_set '/label_' num2str(cam)]);
cfg.calib_dir = fullfile(kitti_dir,['/object/' data_set '/calib']);
cfg.image_r_dir = fullfile(kitti_dir,['/object/' data_set '/image_3']);

% compute road plane in 'fast' mode or 'robust' mode
cfg.plane_mode = 'fast'; 
% road plane path
cfg.plane_dir = fullfile(kitti_dir, ['/object/' data_set '/planes']);
mkdir_if_missing(cfg.plane_dir);
cfg.roadmask_dir = fullfile(kitti_dir,['/object/' data_set '/roadnet/road/eval']);
cfg.disparity_dir = fullfile(kitti_dir, ['/object/' data_set '/disparity']);
mkdir_if_missing(cfg.disparity_dir);
