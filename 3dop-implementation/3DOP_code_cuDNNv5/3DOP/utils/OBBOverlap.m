function score = OBBOverlap(bb1, bb2)
% Calculates the intersection/union for a pair of oriented (with respect to gravity) bounding boxes.
%
% Args:
%   bb1 - struct containing a 3D bounding box.
%   bb2 - struct containing a 3D bounding box.
%
% Returns:
%   score - the intersection / overlap of the two bounding boxes.
%

  maskRes = 0.01;

  % Overlap in Z
  [heightIntersection, heightUnion] = get_height_metrics(bb1, bb2);
  
  % Overlap in the XY plane.
  [rectIntersection, rectUnion] = get_rectangular_metrics(bb1, bb2, maskRes);
  
  intersection = heightIntersection * rectIntersection;
  
  vol1 = bb1.l * bb1.h * bb1.w;
  vol2 = bb2.l * bb2.h * bb2.w;
  union = vol1 + vol2 - intersection;
  
%   union = heightUnion * rectUnion;
  score = intersection / union;
end

function [heightIsect, heightUnion] = get_height_metrics(bb1, bb2)
  maxZ1 = bb1.t(2);
  minZ1 = bb1.t(2) - bb1.h;
  
  maxZ2 = bb2.t(2);
  minZ2 = bb2.t(2) - bb2.h;
  
  maxOfMins = max([minZ1, minZ2]);
  minOfMaxs = min([maxZ1, maxZ2]);
  
  heightIsect = max(0, minOfMaxs - maxOfMins);
  
  heightUnion = max([maxZ1, maxZ2]) - min([minZ1, minZ2]);
  heightUnion = heightUnion - max(0, maxOfMins - minOfMaxs);
end

function [rectIsect, rectUnion] = get_rectangular_metrics(bb1, bb2, maskRes)
  [X1, Y1] = get_poly(bb1);
  [X2, Y2] = get_poly(bb2);
  
  if max(X1) < min(X2) || max(X2) < min(X1) || ...
     max(Y1) < min(Y2) || max(Y2) < min(Y1)
    rectIsect = 0;
    rectUnion = [];
    return;
  end
  
  maxs = max([[X1; X2], [Y1; Y2]], [], 1);
  mins = min([[X1; X2], [Y1; Y2]], [], 1);
  
  % Create the rectangular image.
  maskDims = ceil((maxs - mins) / maskRes);
  
  % Create the masks for both bounding boxes.
  X1 = (X1 - mins(1)) / maskRes;
  X2 = (X2 - mins(1)) / maskRes;
  Y1 = (Y1 - mins(2)) / maskRes;
  Y2 = (Y2 - mins(2)) / maskRes;
  
  X1 = round(X1);
  Y1 = round(Y1);
  
  mask1 = poly2mask(X1, Y1, maskDims(2), maskDims(1));
  mask2 = poly2mask(X2, Y2, maskDims(2), maskDims(1));
  maskIsect = mask1 & mask2;
  maskUnion = mask1 | mask2;
  
  rectIsect = nnz(maskIsect) * maskRes^2;
  rectUnion = nnz(maskUnion) * maskRes^2;
end

function [X, Z] = get_poly(bb)
% X     4x1 
% Z     4x1

  % compute rotational matrix around yaw axis
    R = [+cos(bb.ry), +sin(bb.ry);
         -sin(bb.ry), +cos(bb.ry)];

    % 3D bounding box corners
    x_corners = bb.l/2 .* [1, 1 -1 -1];
    z_corners = bb.w/2  .* [1, -1, -1, 1];

    % rotate
    P = R * [x_corners; z_corners];
    
    X = P(1, :)' + bb.t(1);
    Z = P(2, :)' + bb.t(3);
end