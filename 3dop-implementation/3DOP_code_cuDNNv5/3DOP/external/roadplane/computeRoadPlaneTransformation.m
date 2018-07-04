function [R,Tr_cam_plane, Tr_plane, plane_3d] = computeRoadPlaneTransformation(D,intrinsics, ransac_roi)

% get image size
width  = size(D,2);
height = size(D,1);

% road plane segmentation
if nargin < 3
ransac_roi = [200 width-200 round(height/2) height];
end;
if nargin >=3
    plane_dsi  = computeRoadPlaneEstimateMex_roi(D',int32(ransac_roi),int32(300),single(1));
else
    plane_dsi  = computeRoadPlaneEstimateMex(D',int32(ransac_roi),int32(300),single(1));   
end;
R          = segmentRoadPlaneDsi(D,plane_dsi,intrinsics,2);

% compute road<->camera transformations
plane_3d     = roadPlaneDsiTo3d(plane_dsi,intrinsics(1),intrinsics(3),intrinsics(4),intrinsics(5));
Tr_plane = roadPlaneToCameraTransformation(plane_3d);
Tr_cam_plane = inv(Tr_plane);

