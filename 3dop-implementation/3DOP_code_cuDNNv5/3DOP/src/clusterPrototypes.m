function template_cuboids = clusterPrototypes(db, category)
% cluster ground truth cuboids to get object templates

close all; 

% car: 0.6; pedestrian: 0.5; cyclist: 0.55
% overlap_threshold = 0.6;
switch category
    case 'car'
        overlap_threshold = 0.6;
    case 'pedestrian'
        overlap_threshold = 0.5;
    case 'cyclist'
        overlap_threshold = 0.55;
end

grid_dx = 0.2;
grid_dz = 0.2;
grid_dy = 0.2;

cluster_feature = cat(1, db.impos.sizes3D)';

cluster_feature_xyz = cluster_feature(1:3, :);
max_cluster_feature_xyz = max(cluster_feature_xyz(:));
cluster_feature_xyz = cluster_feature_xyz/max_cluster_feature_xyz;

% visualizing dx, dy, dz distribution
temp = cluster_feature_xyz * 10;
freq = temp(1, :)*100 + temp(3, :)*10 + temp(2, :);
[freq, bin] = histc(freq, 0:1330);

freq_mod = freq;
ind = find(freq == 0);
ind = setdiff(1:numel(freq), ind);
freq_mod(freq == 0) = [];
bin_box(1:length(freq_mod)) = struct('x', [], 'y', [], 'z', []);
for i = 1:length(freq_mod)
    clust_ind = bin == ind(i);
    bin_box(i).x = mean(cluster_feature_xyz(1, clust_ind))*max_cluster_feature_xyz;
    bin_box(i).y = mean(cluster_feature_xyz(2, clust_ind))*max_cluster_feature_xyz;
    bin_box(i).z = mean(cluster_feature_xyz(3, clust_ind))*max_cluster_feature_xyz;
end

center_id_list = [];

while nnz(freq_mod) ~= 0
    [max_val, center_id] = max(freq_mod);
    if(max_val == 0)
        break;
    end
    center = bin_box(center_id);
    center_id_list = [center_id_list; center_id];
    
    freq_mod(center_id) = 0;
    
    for i = 1:length(freq_mod)
        if(freq_mod(i) == 0)
            continue;
        end
        overlap = get_overlap(bin_box(i), center);
        if(overlap >= overlap_threshold)
            freq_mod(i) = 0;
            bin(bin == ind(i)) = ind(center_id);
        end
    end
end

count = 0;
cluster_center(1:numel(center_id_list), 1) = struct('x', [], 'y', [], 'z', [], 'count', []);
for i = 1:numel(center_id_list)
    clust_ind = find(bin == ind(center_id_list(i)));
    if(numel(clust_ind) < 2)
        continue;
    end
    count = count + 1;
    cluster_center(count).x =...
        mean(cluster_feature_xyz(1, clust_ind))*max_cluster_feature_xyz; %#ok<*AGROW>
    cluster_center(count).y =...
        mean(cluster_feature_xyz(2, clust_ind))*max_cluster_feature_xyz;
    cluster_center(count).z =...
        mean(cluster_feature_xyz(3, clust_ind))*max_cluster_feature_xyz;
    cluster_center(count).count =...
        numel(clust_ind);
    cluster_center(count).num_grid = [ceil(cluster_center(count).x/grid_dx), ceil(cluster_center(count).y/grid_dz), ceil(cluster_center(count).z/grid_dy)];
end
cluster_center(count + 1:end) = [];

if false
    figure;
    cube_color = lines(numel(cluster_center));
    for i = 1:size(cluster_center)
        dx = cluster_center(i).x;
        dy = cluster_center(i).y;
        dz = cluster_center(i).z;
        x = [0, 0, 0, 0, 0, 0, dx, dx, 0, 0, dx, dx;
            dx, dx, dx, dx, 0, 0, dx, dx, 0, 0, dx, dx];
        y = [0, 0, dy, dy, 0, 0, 0, 0, 0, dy, 0, dy;
            0, 0, dy, dy, dy, dy, dy, dy, 0, dy, 0, dy];
        z = [0, dz, 0, dz, 0, dz, 0, dz, 0, 0, 0, 0;
            0, dz, 0, dz, 0, dz, 0, dz, dz, dz, dz, dz];
        line(x, y, z, 'color', cube_color(i, :))
        hold on
    end
    xlabel('x');
    ylabel('y');
    zlabel('z');
end

template_cuboids = cluster_center(1:3);

function [overlap] = get_overlap(a, b)

overlap = zeros(length(b), 1);
for i = 1:length(b)
intersection = min(a.z, b(i).z) * max(min(a.x, b(i).x)*min(a.y, b(i).y),...
    min(a.x, b(i).y)*min(a.y, b(i).x));
overlap(i) = intersection/((a.x*a.y*a.z) + (b.x*b.y*b.z) - intersection);
end

