function [boxes, scores, boxes3D, fs] ...
                = boxes_infer(xyz, plane, camdata, model, im_size, training)
% Inference of 3D Object Proposals
%
% INPUT
%   xyz         Nx3 matrix containing the point cloud. X: right, Y: down, Z:
%               forward
%   plane       4x1 vector, the ground plane
%   camdata     a structure containing the camera matrix
%   model       proposal model
%   im_size     image size
%   training    set true if training and false otherwise
%
% OUTPUT
%   boxes       Nx4 matrix with each row indicating a 2D box [x1 y1 x2 y2]
%   scores      Nx1 vector, proposal scores
%   boxes3D     Nx7 matrix with each row indicating a 3D box 
%               [ry l h w x y z]
%   fs          Nx5 matrix with each row indicating a feature vector
%

%% Parameters
% prior parameters
heightMean = model.params.heightMean;
heightSigma = model.params.heightSigma;
% sampling parameters
dist2RoadMean = model.params.dist2RoadMean;      % distance between bounding boxes and the ground plane
dist2RoadSigma = model.params.dist2RoadSigma;
dist2RoadExt = model.params.dist2RoadExt;
dist2RoadMax = model.params.dist2RoadMax;
maxScope = model.params.maxScope;
voxelSize = model.params.voxelSize;
minPointsInGrid = model.params.minPointsInGrid;  % remove bounding boxes containing less than a certain number of points
extSampling = model.params.extSampling;          % do more sampling in far distance (>20m)

templates = model.templates;
% default height of the camera in KITTI setting
CAMERA_HEIGHT = 1.65;

%% read point clouds
% if road estimation fails, set height to default value
if isempty(plane)
    plane = [0; -1; 0; CAMERA_HEIGHT];
end
% make sure the normal of road plane is facing up
% X: right; Y: down; Z: forward
if plane(2) > 0
    plane = -plane;
end
plane = plane(:);

%% voxelization
% compute ROI
dist_g = [xyz, ones(size(xyz,1), 1)] * plane;
scope_ids = dist_g < dist2RoadMax & sum(xyz.^2,2) <= maxScope^2;
xyz = xyz(scope_ids, :);
dist_g = dist_g(scope_ids);
% road points
road_ids = dist_g <= 0.08;

roi_ids = true(size(xyz,1), 1);
roi_ids(road_ids) = false;
roi = xyz(roi_ids, :);
% clip Y values
roi(roi(:,2) > 3, 2) = 3;

voxelGrid = voxelize(roi, voxelSize);

%% 3D Integral Images
% point cloud occupancy
pointSpace = voxelGrid.leafLayout > 0;
intImg_pc = integralImage3D(pointSpace);

% free space
freeSpace = computeFreeSpace(voxelGrid, double(pointSpace));
intImg_freeSpace = integralImage3D(freeSpace);

% heigh prior
dist_g = [voxelGrid.voxels, ones(size(voxelGrid.voxels,1), 1)] * plane(:);
height_prior = exp(- (dist_g - heightMean).^2 ./ (2 * heightSigma^2));
heightPrior = zeros(voxelGrid.numDivisions);
heightPrior(pointSpace) = height_prior(:);
intImg_prior = integralImage3D(heightPrior);


%% sampling
boxes3D = cell(length(templates), 1);
boxesCoords = boxes3D;      % 1-based grid coordinates
f_g = boxes3D;
boxes = boxes3D;
point_counts = boxes3D;
for k = 1 : length(templates)
    ry = templates(k).ry;
    l = templates(k).l;
    w = templates(k).w;
    h = templates(k).h;
    dy = round(h/voxelSize);
    if abs(ry - pi/2) < 0.0001
        % rotate 90 degree
        dz = round(l/voxelSize);
        dx = round(w/voxelSize);
    else
        dx = round(l/voxelSize);
        dz = round(w/voxelSize);
    end

    maxCoords = voxelGrid.numDivisions - [dx, dy dz] + 1;
    [minxs, minzs] = meshgrid(1:maxCoords(1), 1:maxCoords(3));
    minxs = minxs(:);
    minzs = minzs(:);
    
    % centers of the bottom faces, convertion from 1-based discrectized values to continuous values
    txzs = voxelGrid.D2C([minxs+dx/2-0.5, minzs+dz/2-0.5], [1,3]);        
    tmp = (-plane(4) - txzs * plane([1,3])) ./ (plane(2) + eps);
    dists =  dist2RoadMean;
    % do more sampling in large distance for robust estimation
    if extSampling
        dists = [dist2RoadMean, dist2RoadExt];
        minxs = repmat(minxs, length(dists), 1);
        minzs = repmat(minzs, length(dists), 1);
    end
    maxys = bsxfun(@plus, dists./plane(2), tmp);
    dists_n = exp(-(dists - dist2RoadMean).^2 ./ (2 * dist2RoadSigma^2));
    ground_dist = repmat(dists_n, size(maxys,1), 1);
    maxys = maxys(:);
    ground_dist = ground_dist(:);    
    
    % from continuous values to 1-based discrectized values
    maxys = max(dy, voxelGrid.C2D(maxys, 2));
    minys = max(maxys(:)-dy+1, 1);
    % [x1 y1 z1 x2 y2 z2]
    sample_boxes = [minxs(:), minys, minzs(:), minxs(:)+dx-1, maxys(:), minzs(:)+dz-1];
    % skip empty boxes
    counts = intImg_pc.query(sample_boxes);

    sel = counts > minPointsInGrid;
    sample_boxes = sample_boxes(sel, :);
    boxesCoords{k} = sample_boxes;
    f_g{k} = ground_dist(sel);
    point_counts{k} = counts(sel);

    centers = [mean(sample_boxes(:,[1,4]),2), mean(sample_boxes(:,[2,5]),2), mean(sample_boxes(:,[3,6]),2)];
    % from 1-based discrectized values to continuous values
    ts = voxelGrid.D2C(centers);
    ts(:,2) = ts(:,2) + h/2;
    boxes3D{k} = [repmat([ry, l, h, w], size(ts,1), 1), ts];
    boxes{k} = projectBB_batch(ry, l, h, w, ts, camdata.P_left);
end
boxesCoords = cat(1, boxesCoords{:});   % [x1, y1, z1, x2, y2, z2], 1-based index
boxes3D = cat(1, boxes3D{:});           % [ry, l, h, w, tx, ty, tz]
boxes = cat(1, boxes{:});
f_g = cat(1, f_g{:});
point_counts = cat(1, point_counts{:});

% clip to image boundaries
boxes(:,1:2) = max(boxes(:,1:2), 0);
boxes(:,3) = min(boxes(:,3), im_size(2));
boxes(:,4) = min(boxes(:,4), im_size(1));
% filter out very small boxes
hs = boxes(:, 4) - boxes(:, 2) + 1;
ws = boxes(:, 3) - boxes(:, 1) + 1;
sel = hs >= 15 & ws >= 5;
boxes = boxes(sel, :);
boxes3D = boxes3D(sel, :);
boxesCoords = boxesCoords(sel, :);
f_g = f_g(sel, :);
point_counts = point_counts(sel, :);

%% features
% point cloud occupancy
dxyz = boxesCoords(:, 4:6) - boxesCoords(:,1:3) + 1;
boxVols = prod(dxyz, 2);
f_pc = point_counts ./ boxVols;

% free space
freeSpaceSize = intImg_freeSpace.query(boxesCoords);
% f_free = 1 - freeSpaceSize ./ boxVols;
f_free = - freeSpaceSize ./ boxVols;

% height prior
face_areas = dxyz(:,1).*dxyz(:,2) + dxyz(:,2).*dxyz(:,3) + dxyz(:,3).*dxyz(:,1);
prob_sum = intImg_prior.query(boxesCoords);
f_h = min(prob_sum ./ face_areas * 3, 1.0);

% height contrast
ext = round(0.6 / voxelSize);
boxesSurround = boxesCoords;
boxesSurround(:,1:3) = max(boxesSurround(:,1:3) - ext, 1);
boxesSurround(:,4:6) = bsxfun(@min, boxesSurround(:,4:6) + ext, voxelGrid.numDivisions);
prob_sum_srd = intImg_prior.query(boxesSurround);
f_hc = prob_sum ./ (prob_sum_srd - prob_sum + eps);
f_hc = 1 - exp(-f_hc.^2 ./ 2);

fs = [f_h, f_hc, f_g,  f_pc, f_free];
scores = [];

%% scoring
if ~training
    weights = model.ssvm.weights;
    scores = fs * weights(:);
    [~, ids] = sort(scores, 'descend');
    sel = ids(1:min(length(ids), 200000));
    
    scores = scores(sel);
    boxes = boxes(sel, :);
    boxes3D = boxes3D(sel, :);     
        
    % NMS, takes at most 5K proposals
    nms_thr = model.params.nms;    
    [boxes_nms, ids] = boxesNMS(uint32(boxes), single(scores), nms_thr, 5000);
    boxes = boxes_nms(:,1:4);
    scores = boxes_nms(:, 5);
    boxes3D = boxes3D(ids, :);
end

end
