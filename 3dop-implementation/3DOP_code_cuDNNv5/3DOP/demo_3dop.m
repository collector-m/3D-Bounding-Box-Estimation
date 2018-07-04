% 3D Object Proposals (3DOP) [http://www.cs.toronto.edu/~objprop3d/]
% Demo scripts for training, testing and evaluation.
%
% Copyright (c) 2015 <Xiaozhi Chen, Kaustav Kunku, Yukun Zhu, 
% Andrew Berneshawi, Huimin Ma, Sanja Fidler and Raquel Urtasun>
%

%% configuration
% Edit kitti_dir.m for KITTI data directory
%
% Download pre-computed SPS-stereo disparity and road planes from the
% project page: http://www.cs.toronto.edu/~objprop3d/, and put them under
% the KITTI object dataset path which is specified in kitti_dir
%
% If you don't download the pre-computed disparity, you need to compile 
% ./external/spsstereo
%
% Compile mex functions:
% >> compile

% demo
startup;

% proposal type: 
% 'class' - class-dependent proposals
% 'generic' - class-independent proposals
type = 'class';

% category: 'car', 'pedestrian', or 'cyclist'
category = 'car';
% training set: 'train' or 'trainval'
trainset = 'train';
% test set: 'val' or 'test'
testset = 'val';
% difficulty level, 1: easy, 2: moderate, 3: hard
level = 2;

%% evaluation
% We provide pre-computed proposals in the project page: 
% http://www.cs.toronto.edu/~objprop3d/
% You can download them and put them under ./proposals
eval_proposals(category, level, testset);

%% illustration
eval_illustrate;

%% training 
% Please download pre-computed disparity and road planes from the project
% page: http://www.cs.toronto.edu/~objprop3d/, and put them under the KITTI
% data path, i.e., {kitti_dir}/object/training/ and
% {kitti_dir}/object/testing/

% cache features for SSVM training (requires ~30G disk space)
if strcmp(type, 'class')
    exp_cache_features(trainset, category);
elseif strcmp(type, 'generic')
    exp_cache_features(trainset);
end

% After caching the features, do SSVM training with following steps:
% 1. install dependencies: Gurobi, Eigen
% 2. cd ./external/ssvm
% 3. edit CMakeList.txt to point to Gurobi path
% 4. compile: cmake . && make
% 5. edit and run train_ssvm.sh or train_ssvm_generic.sh

%% testing
% We provide pre-computed object proposal models in 
% ./data/models (class-dependent) and
% ./data/models-generic (class-independent)

% compute proposals
if strcmp(type, 'class')
    exp_compute_proposals(trainset, testset, category);
elseif strcmp(type, 'generic')
    exp_compute_proposals(trainset, testset);
end
