function [ boxes ] = projectBB_batch(ry, l, h, w, ts, P)
%PROJECTBB_BATCH Summary of this function goes here
%   Detailed explanation goes here

% index for 3D bounding box faces
face_idx = [ 1,2,6,5   % front face
             2,3,7,6   % left face
             3,4,8,7   % back face
             4,1,5,8]; % right face

% compute rotational matrix around yaw axis
R = [+cos(ry), 0, +sin(ry);
     0, 1,               0;
     -sin(ry), 0, +cos(ry)];


% 3D bounding box corners
x_corners = [l/2, l/2, -l/2, -l/2, l/2, l/2, -l/2, -l/2];
y_corners = [0,0,0,0,-h,-h,-h,-h];
z_corners = [w/2, -w/2, -w/2, w/2, w/2, -w/2, -w/2, w/2];

% rotate and translate 3D bounding box
corners_3D = R*[x_corners;y_corners;z_corners];

corners(1,:,:) = bsxfun(@plus, corners_3D(1,:), ts(:,1)); % nx8
corners(2,:,:) = bsxfun(@plus, corners_3D(2,:), ts(:,2));
corners(3,:,:) = bsxfun(@plus, corners_3D(3,:), ts(:,3));

corners = reshape(corners, 3, []);
% project the 3D bounding box into the image plane
corners_2D = projectToImage(corners, P);
corners_2D = reshape(corners_2D, 2, size(ts,1), 8); % 2xnx8
corners_2D = permute(corners_2D, [3,1,2]); % 8x2xn

minxy = min(corners_2D, [], 1); % 1x2xn
maxxy = max(corners_2D, [], 1);

boxes = [squeeze(minxy(1,1,:)), squeeze(minxy(1,2,:)), ...
    squeeze(maxxy(1,1,:)), squeeze(maxxy(1,2,:))];

end

