function [ camdata ] = getCamData( calib_dir, id )

[~, ~, calib] = loadCalibration(sprintf('%s/%s.txt',calib_dir, id));
[Kl,~,tl] = KRt_from_P(calib.P_rect{3});  % left camera
[~,~,tr] = KRt_from_P(calib.P_rect{4});  % right camera
f = Kl(1,1);
baseline = abs(tr(1)-tl(1));   % distance between cams
camdata = struct;
camdata.f = f;
camdata.baseline = baseline;
camdata.K = Kl;
camdata.P_left = calib.P_rect{3};
camdata.P_right = calib.P_rect{4};
camdata.cu = Kl(1,3);
camdata.cv = Kl(2,3);

% camdata.Tr_velo_to_cam = readCalibration(calib_dir, str2double(id), 5);

end

