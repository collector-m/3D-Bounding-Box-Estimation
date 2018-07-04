function plane_3d = roadPlaneDsiTo3d(plane_dsi,f,cx,cy,base)

a     = plane_dsi(1);
b     = plane_dsi(2);
c     = plane_dsi(3);

plane_3d(1) = a/base;
plane_3d(2) = b/base;
plane_3d(3) = (a*cx+b*cy+c)/(f*base);

plane_3d = plane_3d;
