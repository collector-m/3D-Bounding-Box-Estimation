import numpy as np
import os
import sys
import pdb
import glob
import cv2
import scipy.io

def main():

	datadir = '/media/rajatmittal/1a4b8e66-3d01-4a83-8e7b-52054acd44f2/kitti-stereo-dataset/disparity'
	#load disparity image
	
	for i in range(0, 7481):
		temp_str = '000000'
		temp_str = temp_str + str(i) + '.png' 
		temp_str = temp_str[-10:]
		img = os.path.join(datadir, temp_str)
		print img
		disparity = cv2.imread(img)
		#cv2.imshow('image', disparity)
		#print(disparity.shape[:2])
		#print(disparity[350,1100,:])
		#cv2.waitKey(0)
		#print i
		xyz = disparity2depth(disparity)
		pcldir = 'data/pcl'
		temp_str2 = str(i) + '.mat'
		file = os.path.join(pcldir, temp_str2)
		scipy.io.savemat(file, mdict={'xyz': xyz})
		#cv2.waitKey(0)
		#scipy.io.savemat('xyz.mat', mdict={'xyz': xyz})



def disparity2depth(disparity, Q=None):
    # Obtain xyz coordinates in rect space from disparity map
    # Inputs: left image, and disparity map, and Q matrix
    if Q is None: Q = compute_Q(disparity.shape[:2])
    disp = disparity[:,:,1] 
    points = cv2.reprojectImageTo3D(disp, Q)
    #colors = cv2.cvtColor(img_left, cv2.COLOR_BGR2RGB)
    #mask = disp > disp.min()
    #ut_points = points[mask]
    #out_colors = colors[mask]
    #return out_points, out_colors
    return points

def compute_Q(imsize):
	R = np.array([[1.0, 0.0, 0.0],[0.0, 1.0, 0.0], [0.0, 0.0, 1.0]])
	K1 = np.array([[7.215377000000e+02, 0.000000000000e+00, 6.095593000000e+02], [0.000000000000e+00, 7.215377000000e+02, 1.728540000000e+02], [0.000000000000e+00, 0.000000000000e+00, 1.000000000000e+00]])
	K2 = np.array([[7.215377000000e+02, 0.000000000000e+00, 6.095593000000e+02], [0.000000000000e+00, 7.215377000000e+02, 1.728540000000e+02], [0.000000000000e+00, 0.000000000000e+00, 1.000000000000e+00]])
	T = np.array([-0.54, 0.0, 0.0])
	#K1 = np.zeros((3,3))
	#K2 = np.zeros((3,3))
	#T = np.zeros((3,1))
	#R = np.zeros((3,3))
	#imsize = disparity.shape[:2]
	#R1, R2, P1, P2, Q, roi1, roi2 = 
	#R1 = np.zeros((3,3))
	#R2 = np.zeros((3,3))
	#P1 = np.zeros((3,4))
	#P2 = np.zeros((3,4))
	#R1, R2, P1, P2, Q = None,
	R1, R2, P1, P2, Q, roi1, roi2 = cv2.stereoRectify(
            K1, 
            np.zeros(5),
            K2, 
            np.zeros(5),
            imsize,
            R, 
            T, 
            alpha=1.0, newImageSize=(0, 0))
	#print(Q)
	return Q 
   # R = self.calib['R_03'].reshape(3,3).dot(
   #        np.linalg.inv(self.calib['R_02'].reshape(3,3)))
   # T = self.calib['T_03'] - self.calib['T_02']
    
	 
    #imsize = np.array([1224, 370])
    

       


if __name__ == '__main__':
	main()