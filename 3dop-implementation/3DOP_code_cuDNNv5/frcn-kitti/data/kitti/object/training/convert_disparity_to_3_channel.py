import numpy as np
import cv2
import os
import sys

if __name__ == "__main__":
	dispdir = 'disparity'
	imgdir = 'image_2'
	temp = "000000"
	for i in range(0, 7481):
		fname = temp + str(i) + ".png"
		fname = fname[-10:]
		img = os.path.join(dispdir, fname)
		disp = cv2.imread(img)
		img = os.path.join(imgdir, fname)
		image = cv2.imread(img)
		print image.shape
		print disp.shape
		sh = disp.shape
		channel_swap = (2, 0, 1)
		image = image.transpose(channel_swap)
		disp = disp.transpose(channel_swap)
		print image.shape
		print disp.shape
		final_image = np.zeros((6, sh[0], sh[1]))
		final_image[0] = image[0]
		final_image[1] = image[1]
		final_image[2] = image[2]
		final_image[3] = disp[0]
		final_image[4] = disp[1]
		final_image[5] = disp[2]
		channel = (1, 2, 0)
		final_image = final_image.transpose(channel)
		print final_image.shape
		cv2.imwrite(fname, final_image)