function savemat2txt(mat, fname, ftype, dtype)
%SAVEMAT2TXT Summary of this function goes here
%   Detailed explanation goes here

assert(ndims(mat) == 2, 'The matrix should contain 2 dimensions');

if nargin < 3
    ftype = 'txt';
end

[rows, cols] = size(mat);


fid = fopen(fname, 'w');
if strcmp(ftype, 'txt')
    fprintf(fid, '# Matrix\n');
    fprintf(fid, 'WIDTH %d\nHEIGHT %d\n', cols, rows);
    for i = 1 : rows
        fprintf(fid, '%d ', mat(i,:));
        fprintf(fid, '\n');
    end
elseif strcmp(ftype, 'bin')
    if nargin < 4
        dtype = 'float';
    end
    fwrite(fid, [rows; cols], dtype);
    fwrite(fid, mat, dtype);
else
    error('wrong file type\n');
end

fclose(fid);


end

