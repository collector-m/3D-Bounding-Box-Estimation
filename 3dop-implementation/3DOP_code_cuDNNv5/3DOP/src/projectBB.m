function [ boxes ] = projectBB(box3D, P)
%PROJECTBB_BATCH Summary of this function goes here
%   Detailed explanation goes here

assert(size(box3D,1) == 1);
% compute rotational matrix around yaw axis
ry = box3D(1);
l = box3D(2);
h = box3D(3);
w = box3D(4);

R = [+cos(ry), 0, +sin(ry);
     0, 1, 0;
     -sin(ry), 0, +cos(ry)];


% 3D bounding box corners
x_corners = l/2 .* [1, 1, -1, -1, 1, 1, -1, -1];
y_corners = -h .* [0,0,0,0,1,1,1,1];
z_corners = w/2 .*[1, -1, -1, 1, 1, -1, -1, 1];

% rotate and translate 3D bounding box
corners_3D = R*[x_corners;y_corners;z_corners];     % 3x8
corners = bsxfun(@plus, corners_3D, box3D(5:7)');

% project the 3D bounding box into the image plane
corners_2D = projectToImage(corners, P);        % 2x8

boxes = round([min(corners_2D,[],2)', max(corners_2D,[],2)']);


end

