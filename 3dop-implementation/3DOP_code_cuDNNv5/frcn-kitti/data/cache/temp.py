import numpy as np
import sys
import os
import pickle

with open('kitti_car_train_3DOP_top2000_roidb.pkl', 'rb') as f:
	data = pickle.load(f)

with open('kitti_car_train_gt_roidb.pkl', 'rb') as f:
	data_gt = pickle.load(f)

for key in data[1]:
	print "key is:", key

for key in data_gt[1]:
	print "key is:", key
print type(data[1])
print np.shape(data[0]['boxes3D'])
print data[0]['boxes3D'][0]
#print data['boxes3D'][1][0]
