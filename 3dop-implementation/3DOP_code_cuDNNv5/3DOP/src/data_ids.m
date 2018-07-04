function [ image_ids ] = data_ids( split )
% Get data split: 'train', 'val', 'trainval', 'test'
% The train/val split was made so that frames from the same sequence do not
% fall in both the training and validation sets.

image_ids = textscan(fopen(sprintf('data/ImageSets/%s.txt', split)), '%s');
image_ids = image_ids{1};

end

