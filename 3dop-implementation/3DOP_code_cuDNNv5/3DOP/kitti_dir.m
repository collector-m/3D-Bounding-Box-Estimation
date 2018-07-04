function [kitti_dir, cache_dir] = kitti_dir()
% paths for KITTI data and feature caching

% Specify KITTI data path so that the structure is like
% {kitti_dir}/object/training/image_2
%                            /image_3
%                            /calib
%                            /disparity
%                            /planes
%
% {kitti_dir}/object/testing/image_2
%                           /image_3
%                           /calib
%                           /disparity
%                           /planes
%
kitti_dir = '/w/datasets/kitti';

% cache folder for features
cache_dir = '/u/xiaozhi/cache/3DOP';

end

