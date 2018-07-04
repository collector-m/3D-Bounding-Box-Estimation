function voxelGrid = voxelize(xyz, voxelSize)
% voxelization
% xyz       Nx3 matrix indicating [x y z] coordinates

assert(size(xyz,2) == 3, 'size(xyz,2) == 3');
voxelCoords = floor(xyz ./ voxelSize);
[voxelCoords, voxelID] = unique(voxelCoords, 'rows');
voxelGrid.voxels = xyz(voxelID, :);

voxelGrid.voxelSize = voxelSize;
voxelGrid.voxelID = voxelID;
voxelGrid.minVoxelCoord = min(voxelCoords, [], 1);
% extend nearby space to cover trucated cars
voxelGrid.minVoxelCoord(3) = max(voxelGrid.minVoxelCoord(3) - round(1/voxelSize), 0);
voxelGrid.maxVoxelCoord = max(voxelCoords, [], 1);
% extend the lowest space to reduce error caused by road estimation
voxelGrid.maxVoxelCoord(2) = voxelGrid.maxVoxelCoord(2) + round(0.5/voxelSize);
voxelGrid.numDivisions = voxelGrid.maxVoxelCoord - voxelGrid.minVoxelCoord + 1;
voxelGrid.divMultiplier = [1, voxelGrid.numDivisions(1), ...
    voxelGrid.numDivisions(1) * voxelGrid.numDivisions(2)];

occupancyID = sum(bsxfun(@times, bsxfun(@minus, voxelCoords, voxelGrid.minVoxelCoord), ...
    voxelGrid.divMultiplier), 2) + 1;
% -1 indicates free/occluded space
voxelGrid.leafLayout = -ones(voxelGrid.numDivisions); 
voxelGrid.leafLayout(occupancyID) = 1 : size(voxelCoords, 1);
voxelGrid.voxelCoords = voxelCoords;

% voxel helpers
voxelGrid.D2C = @D2C;
voxelGrid.C2D = @C2D;

function c = D2C(d, dim)
% convert 1-based discrectized values to continuous values
% d     Nxlength(dim)

    if nargin < 2
        dim = 1:3;
    end
    c = bsxfun(@plus, d, voxelGrid.minVoxelCoord(dim)-1) * voxelGrid.voxelSize;
end

function d = C2D(c, dim)
% convert continuous values to 1-based discrectized values
% c     Nxlength(dim)

    if nargin < 2
       dim = 1:3;    
    end
    d = max(1, bsxfun(@min, voxelGrid.numDivisions(dim), ...
        floor(c ./ voxelGrid.voxelSize) - voxelGrid.minVoxelCoord(dim) + 1));
end

end