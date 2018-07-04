function [ disparity ] = computeDisparity(id, cfg)
% compute disparity using SPS-stereo code:
% http://ttic.uchicago.edu/~dmcallester/SPS/index.html
%

disparity_file = fullfile(cfg.disparity_dir, sprintf('%s_left_disparity.png', id));
try
  disparity = imread(disparity_file);
catch
    try
        file_left = sprintf('%s/%s.png', cfg.image_dir, id);
        file_right = sprintf('%s/%s.png', cfg.image_r_dir, id);
        system(['external/spsstereo/spsstereo ' file_left ' ' file_right]);
        disparity = imread(sprintf('%s_left_disparity.png', id));

        system(sprintf('rm -rf %s_boundary.png %s_plane.txt %s_segment.png %s_label.txt', id, id, id, id));
        system(sprintf('mv %s_left_disparity.png %s', id, cfg.disparity_dir));
    catch
        error('Please compile external/spsstereo first.\n');
    end
end

end