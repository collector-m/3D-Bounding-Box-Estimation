function Tr = roadPlaneToCameraTransformation(plane_3d)

% r2 (facing bottom) = normal vector
r2 = (plane_3d/norm(plane_3d))';

% r1 (facing right) is defined by the following constraints:
% - z=0
% - r2'*r1=0
% - norm(r1)=1
r1x = +sqrt(r2(2)*r2(2)/(r2(1)*r2(1)+r2(2)*r2(2))); % pos => to the right
r1y = -r1x*r2(1)/r2(2);
r1  = [r1x;r1y;0];

% r3 (facing forward) is the cross product
r3 = cross(r1,r2);

% put rotation matrix together
R = [r1 r2 r3];

% center base "below" camera coordinates
t = [0;1/plane_3d(2);0]; % warum/plane_3d(2)? => ah

% create 3d homography
Tr = [R t; 0 0 0 1];
