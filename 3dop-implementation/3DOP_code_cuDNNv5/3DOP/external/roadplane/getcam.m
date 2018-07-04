function P = getcam(calibfile, cam, f)

% f is the image resize factor

if nargin < 3
    f = 1;
end;
   fid = fopen(calibfile);
  % load 3x4 projection matrix
    C = textscan(fid,'%s %f %f %f %f %f %f %f %f %f %f %f %f',4);
  for i=0:11
    P(floor(i/4)+1,mod(i,4)+1) = C{i+2}(cam+1);
  end
  
  % load R_rect
%   C = textscan(fid,'%s %f %f %f %f %f %f %f %f %f',1);
  
  % load velo_to_cam
%   C = textscan(fid,'%s %f %f %f %f %f %f %f %f %f %f %f %f');
  
  fclose(fid);

    P = diag([f,f,1]) * P;