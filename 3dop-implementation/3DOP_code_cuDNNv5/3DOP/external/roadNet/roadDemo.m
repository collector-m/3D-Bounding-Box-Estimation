mfilepath=fileparts(which(mfilename));
addpath(fullfile(mfilepath, 'devkit'))
addpath(fullfile(mfilepath, 'matlab'))

% NOTE that you need spsstereo, found here:
% http://ttic.uchicago.edu/~dmcallester/SPS/
% Download and compile it, and put an "spsstereo" folder in the ../external
% folder, with the binary called "spsstereo" in the root of that folder
% You also need the neural network toolbox of Matlab

%% Testing only
% We provide a model trained on KITTI road training set, the trained net
% is in ./data/trainedNet.mat
% If you just want to evaluate, lets say on KITTI object training set,
% you just need to creat a soft link of the images in
% data/object_training/, so that it has left and right images in image_2 
% and image_3 respectively. Then you can run:

dataDir = 'data'; outDir = 'data';
dh = DataHandler(outDir, dataDir);
roadNet = RoadNet(dh, false, false, 'data/trainedNet.mat');
roadNet.prepAndEval(dh.SET_TEST, roadNet.testIds);

% This will output the road planes of the evaluated dataset to:
% data/object_training/roadnet/road/eval/
% After this, you can read the road planes in that folder using function
% computeRoadPlane.m 


%% Training and testing
% We use the KITTI road dataset to train a road classifier and test on
% object dataset. It will default to looking for data under ./data
% Format should be as if KITTI data was extracted into ./data folder, so
% data/road_training and data/object_training

dh = DataHandler();
roadNet = RoadNet(dh);
roadNet.runAll()

% Note that the first run will be pretty slow as it has to generate all the
% stereo files, but it will be faster after that if you tweak something and
% rerun.
% The DataHandler class is actually very configurable and you can change
% all sorts of paths, almost nothing is hardcoded so take a look at the
% fields and set them as you like