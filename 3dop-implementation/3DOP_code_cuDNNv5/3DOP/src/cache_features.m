function cache_features(id, model, objects, cfg)
% cache features for S-SVM training

feat_dir = cfg.feat_dir;

camdata = getCamData(cfg.calib_dir, id);

% compute depth from disparity
disparity = computeDisparity(id, cfg);
xyz = depthFromDisparity(disparity, camdata);
% road extimation 
plane = computeRoadPlane(id, disparity, camdata, xyz, cfg);

% compute featuers
[boxes, ~, boxes3D, fs] = ...
    boxes_infer(xyz, plane, camdata, model, objects.img_size, 1);

assert(size(boxes, 1) == size(fs,1) & size(boxes3D, 1) == size(fs,1));

%% 3D loss
iou3D = zeros(length(objects.types), 1);
best_ids3D = iou3D;
iouLoss3D = cell(length(objects.types), 1);
feats = cell(length(objects.types), 1);
dists = pdist2(boxes3D(:,[5,7]), objects.t(:,[1,3]));
[min_dists, assign] = min(dists, [], 2);
for j = 1 : length(objects.types)
    cuboid = struct;
    cuboid.l = objects.sizes3D(j,1);
    cuboid.h = objects.sizes3D(j,2);
    cuboid.w = objects.sizes3D(j,3);
    cuboid.ry = objects.ry(j);
    cuboid.t = objects.t(j,:);
    
    sel = assign == j;
    bbs3D = boxes3D(sel, :);
    center_dists = min_dists(sel, :);
    % only compute overlaps with nearby boxes
    thresholds = bsxfun(@plus, sqrt(sum(bbs3D(:,[2,4]).^2, 2))./2, ...
                        sqrt(sum(objects.sizes3D(j,[1,3]).^2, 2))./2);
    nearby_ids = center_dists < thresholds;
    bbs = bbs3D(nearby_ids, :);

    iouLoss3D{j} = zeros(size(bbs3D,1), 1);
    if isempty(bbs)
        iou3D(j) = 0;
        best_ids3D(j) = 1;
    else
        iou = OBBOverlap_batch(cuboid, bbs);
        [iou3D(j), best_id] = max(iou);
        ids = find(nearby_ids);
        best_id = ids(best_id);
        best_ids3D(j) = best_id;
        iouLoss3D{j}(nearby_ids) = iou;
        feats{j} = fs(sel, :);
    end
end

%% cache features for S-SVM training
% IoU threshold for positive samples for S-SVM
iou_thr = model.ssvm.iou;
posID = find(iou3D >= iou_thr);
for i = 1 : length(posID)
    gt_id = posID(i);
    % features
    save_file = sprintf('%s/%s_%d.feat', feat_dir, id, gt_id);
    savemat2txt(feats{gt_id}, save_file, 'bin');
    
    % loss
    save_file = sprintf('%s/%s_%d.loss', feat_dir, id, gt_id);
    savemat2txt(iouLoss3D{gt_id}, save_file, 'bin');
    
    % index of positive example
    save_file = sprintf('%s/%s_%d.pos%02.0f', feat_dir, id, ...
                        gt_id, iou_thr*100);
    best_id = best_ids3D(gt_id);
    posInfo = [best_id-1; iou3D(gt_id)];
    savemat2txt(posInfo, save_file);
end

end

