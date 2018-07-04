import numpy as np
import sys
import os
import pickle

with open('detections.pkl', 'rb') as f:
	data = pickle.load(f)

#total_detections, nn =  np.shape(data['boxes'][1][5])
f = open('val.txt', "r")
#lines = f.readlines()
#print lines
for i in range(0, 3768):
	total_detections, nn =  np.shape(data['boxes'][1][i])
	fname = f.readline()
	fname = fname.rstrip('\n')
	#print fname

	outF = open(fname + ".txt", "w")
	for j in range(0, total_detections):
		line = "Car" + " 0" + " 0 " + str(data['alphas'][1][i][j][0]) + " " + str(data['boxes'][1][i][j][0]) + " " + str(data['boxes'][1][i][j][1]) + " " \
		+ str(data['boxes'][1][i][j][2]) + " " + str(data['boxes'][1][i][j][3]) + " " + str(data['boxes3D'][1][i][j][2]) + " " + str(data['boxes3D'][1][i][j][3]) + " " \
		+ str(data['boxes3D'][1][i][j][1]) + " " + str(data['boxes3D'][1][i][j][4]) + " " + str(data['boxes3D'][1][i][j][5]) + " " + str(data['boxes3D'][1][i][j][6]) + " " \
		+ str(data['boxes3D'][1][i][j][0]) + " " + str(1) 
		outF.write(line)
		outF.write("\n")
	"""	
	line = "Car" + " 0" + " 0 " + "0" + " " + "0"+ " " + "0" + " " \
		+ "0"+ " " + "0"+ " " + "0"+ " " + "0" + " " \
		+ "0" + " " + "0" + " " + "0" + " " + "0" + " " \
		+ "0" + " " + str(1) 
	outF.write(line)
	outF.write("\n")
	"""
outF.close()
f.close()

#	data['boxes'][1][i]
#for key, value in data.iteritems() :#
#	print key, value
#	raw_input("Press Enter to continue")

#for key in data:
#	print "key is:" + key 
#print type(data)
