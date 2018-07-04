function [ model ] = loadModel_generic(trainset)

priorModel = computePrior_generic(trainset);
params = priorModel.params;
template_cuboids = priorModel.template_cuboids;

params.dist2RoadMax = 2;           % max height to the road plane
params.voxelSize = 0.2;            % voxel size for point cloud discritization
params.minPointsInGrid = 10;       % remove bounding boxes containing less than a certain number of point
params.extSampling = true;         % do more sampling by deviating the ground plane

% IoU threshold for NMS and SSVM training
params.nms = 0.7;       % IoU threshold for NMS
ssvm.iou = 0.6;         % IoU threshold for SSVM training

% object prototypes
nt = 0;
for t = 1 : length(template_cuboids)
    l = template_cuboids(t).x;
    h = template_cuboids(t).y;
    w = template_cuboids(t).z;
    nt = nt + 1;
    templates(nt) = struct('l', l, 'h', h, 'w', w, 'ry', 0, 't', [0,0,0]);  % [dx,dy,dz,ry]
    % use the orthogonal orientation if the aspect ratio of the box is less
    % than 0.8
    if min(l/w, w/l) < 0.8
        nt = nt + 1;
        templates(nt) = struct('l', l, 'h', h, 'w', w, 'ry', pi/2, 't', [0,0,0]);  % [dx,dy,dz,ry]
    end
end

% SSVM weights
if nargin > 0
    model_dir = 'data/models-generic';
    weight_file = sprintf('%s/ssvm_%s', model_dir, trainset);
    if exist(weight_file, 'file')
        fid = fopen(weight_file); 
        num_feats = fread(fid, 1, 'uint32');
        ssvm.weights = fread(fid, num_feats, 'double');
        fclose(fid);
    end
end

model.params = params;
model.templates = templates; 
model.ssvm = ssvm;


