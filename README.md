# 3D-Bounding-Box-Estimation

The aim of the project is to detect cars in the image and obtain accurate 3D bounding boxes around the cars.

An overview of the project can be seen in the presentation [here](https://docs.google.com/presentation/d/1pyKTeHV6fCfuA2JL_4AxyM8y4C8QGraODTAeFzHSKos/edit?usp=sharing). I am currently updating the doc, so my apologies if all of the information is not up to date. 

**Dataset Used** - KITTI 3D Object Detection.
**Languages and Softwares Used** - Python, OpenCV, MATLAB, Caffe, Tensorflow.

There are two main components to the project.  
1. **Generating the training dataset**.  
a. Generating the 3D bounding box proposals. Each proposal is defined by (x,y,z,l,w,h,theta).  
    Step 1 - Use stereo images from KITTI Dataset and feed it to trained MC-CNN Network to obtain disparity images.  
    Step 2 - Use OPENCV, disparity images and camera calibration parameters to obtain a 3D point cloud.  
    Step 3 - Use Selective Search or MS-CNN network to generate 2D bounding box proposals.  
    Step 4 - For each 2D bounding box proposal, obtain a 3D bounding box proposal by using information from 2D bounding box proposal and 3D point cloud to get the (x,y,z) coordinates for each proposal. Use the values (2.5, 1.5, 1.5) as (l,w,h) for each proposal. Consider theta to be 0 degrees for each proposal. 

2. **Training the CNN Network**.  
    Step 1 - I used Fast RCNN Network to train the network. Instead of regressing to 2D bounding boxes, I instead regress to obtain 3D bounding boxes. I followed the instructions from 3DOP paper to train the model.  
    Step 2 - In the 3DOP model, change the .mat files for 3D bounding box proposals to the proposals that I generate.
    
    

**Future Steps** -  
a. I would like to explore more efficient ways of generating the bounding box proposal.  
b. Try other networks like Faster RCNN, YOLO, SSD to generate 3D bounding box outputs.


Accuracy results and more updates on the project to be added by July 26th, 2018.
