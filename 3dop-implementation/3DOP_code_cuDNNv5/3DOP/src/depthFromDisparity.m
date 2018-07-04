function [xyz] = depthFromDisparity(disparity, camdata)
% compute XYZ from disparity map
% disparity     uint16
% xyz           X: right; Y: down; Z: forward

disparity = single(disparity);
disparity = disparity ./ 256;
disparity(disparity == 0) = 0.1;

depth = camdata.f * camdata.baseline ./ double(disparity);

[xx, yy] = meshgrid(1:size(depth,2), 1:size(depth,1));
u = (xx(:) - camdata.cu) .* depth(:) / camdata.f;
v = (yy(:) - camdata.cv) .* depth(:) / camdata.f;

xyz = [u(:), v(:), depth(:)];

end