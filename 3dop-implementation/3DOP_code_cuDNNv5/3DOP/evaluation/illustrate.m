function [best_ids, bo] = illustrate(img, gt, boxes, iou, filename)
% illustrate ground truth bounding boxes and their closest bounding box
% proposals
%
% INPUTS
%   img     - a color image
%   gt      - [nx4] array containing ground truth bounding boxes [left top right bottom]
%   boxes   - [nx4] array containing ground truth bounding boxes [left top right bottom]
%

if nargin < 4
    iou = 0.5;
end
% compute the closest proposals
[bo, bbs, best_ids] = closest_candidates(gt, boxes);

% plot image
imshow(img, 'border', 'tight', 'initialmagnification', 'fit');
hold on;    
for j = 1 : size(gt, 1)
    if bo(j) >= iou
        bb = gt(j,:);
        plot(bb([1 3 3 1 1]), bb([2 2 4 4 2]), 'b', 'linewidth', 3);

        bb = bbs(j, :);
        plot(bb([1 3 3 1 1]), bb([2 2 4 4 2]), 'g', 'linewidth', 3);
    else
        bb = gt(j,:);
        plot(bb([1 3 3 1 1]), bb([2 2 4 4 2]), 'r', 'linewidth', 3);
    end
end

if nargin > 4 && ~isempty(filename)
    set(gcf,'Position', [0, 0, round(size(img,2)*0.5), round(size(img,1)*0.5)]);
    set(gcf, 'paperpositionmode', 'auto');
    print('-dpng','-r200', filename);
end

end

