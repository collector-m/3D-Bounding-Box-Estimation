function intImg = integralImage3D(img)
% 3D integral image
% img       MxMxD matrix

assert(length(size(img)) == 3);

intImg.intImage = cumsum(cumsum(cumsum(img,1),2),3);
intImg.intImage  = single(padarray(intImg.intImage, [1,1,1], 0, 'pre'));
intImg.size = size(intImg.intImage);

% evaluate integral image
intImg.query = @query;

function vals = query(cuboids)
% cuboids     [x1 y1 z1 x2 y2 z2]

    % INPUTS: uint32(boxes), single(integralImage)
    vals = integralImage3DVal_mex(uint32(cuboids)', intImg.intImage, intImg.size);
    
end
end