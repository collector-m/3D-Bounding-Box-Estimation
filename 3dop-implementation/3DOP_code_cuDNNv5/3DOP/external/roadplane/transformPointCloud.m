function points3d = transformPointCloud(points3d, T)

if size(points3d, 2) < 4
    points3d = [points3d, ones(size(points3d, 1), 1)];
end;
points3d = (T * points3d')';
points3d = points3d(:, 1:3);