function eval_proposals(category, level, testset)
% evaluate proposal recall
% INPUT
%   category    'car', 'pedestrian' or 'cyclist'
%   level       difficulty level, 1: easy, 2: moderate, 3: hard
%   testset     'val' or 'test'
%
disp('======= Evaluate KITTI proposals =======');

% category = 'car';
% level = 2; 
% testset = 'val';

db = db_from_kitti(kitti_dir, testset);
db = dbFilter(db, category, level);
cols = lines;

% our method
methods = props_config(category, testset, level, 'generic');
methods.color = cols(1, :);
methods(2) = props_config(category, testset, level);
methods(2).color = cols(2, :);


% evaluate 2D box recall
eval_kitti(db, methods, level, category);

% evaluate 3D box recall
eval_kitti_3D(db, methods, level, category);
