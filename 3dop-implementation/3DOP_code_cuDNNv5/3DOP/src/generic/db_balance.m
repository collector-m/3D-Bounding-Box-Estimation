function db_out = db_balance(db, categories, level)
% Get balanced samples
% As KITTI contains much more car instances than pedestrian/cyclist
% istances, we use a balanced subset by selecting images that contain at 
% least one cyclist instance

db = dbFilter(db, categories, level);

db_out = db;
sel_ids = false(length(db.impos),1);
for i = 1 : length(db.impos)
    sel_ids(i) = any(ismember(db.impos(i).types, db.labelMap('cyclist')));
end

db_out.impos = db_out.impos(sel_ids);


end

