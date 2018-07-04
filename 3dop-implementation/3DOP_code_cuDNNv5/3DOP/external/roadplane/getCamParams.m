function data = getCamParams(testset, videoname)

dataset_globals;
calibmat = fullfile(sprintf(CALIB_DIR_txt, testset), [videoname '.mat']);
if exist(calibmat, 'file')
    data = load(calibmat);
    return;
end;

calibfile = fullfile(CALIB_DIR, [videoname '.txt']);
P_left = getcam(calibfile, 2, 1);
P_right = getcam(calibfile, 3, 1);


    [K_left, R_left, t_left] = art(P_left);
    [K_right, R_right, t_right] = art(P_right);
    
    baseline = abs(t_right(1,1) - t_left(1,1));
    f = K_left(1,1);
    
    save(calibmat, 'baseline', 'f', 'P_left', 'P_right', 'K_left', 'K_right', 't_left', 't_right') 
    data = load(calibmat);