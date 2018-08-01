# 3D-Bounding-Box-Estimation

The aim of the project is to detect cars in the image and obtain accurate 3D bounding boxes around the cars.

An overview of the project can be seen in the presentation [here](https://docs.google.com/presentation/d/1pyKTeHV6fCfuA2JL_4AxyM8y4C8QGraODTAeFzHSKos/edit?usp=sharing). I am currently updating the doc, so my apologies if all of the information is not up to date. 

**Dataset Used** - KITTI 3D Object Detection.  
**Languages and Softwares Used** - Python, OpenCV, MATLAB, Caffe, Tensorflow.

There are two main components to the project.  
1. **Generating the training dataset**.  
a. Generating the 3D bounding box proposals. Each proposal is defined by (x,y,z,l,w,h,theta).  
    Step 1 - Use stereo images from KITTI Dataset and feed it to trained [MC-CNN](https://github.com/jzbontar/mc-cnn) Network to obtain disparity images. The disparity images can be obtained from [here](https://drive.google.com/open?id=1oYSYB2wcLGOaLEoyMxePZg4ED7W1vadN).  
    Step 2 - Use OPENCV, disparity images and camera calibration parameters to obtain a 3D point cloud. The algorithm file for this depthfromdisparity.py.   
    Step 3 - Use Selective Search or MS-CNN network to generate 2D bounding box proposals.  
    Step 4 - For each 2D bounding box proposal, obtain a 3D bounding box proposal by using information from 2D bounding box proposal and 3D point cloud to get the (x,y,z) coordinates for each proposal. Use standard values, for eg. the values (2.5, 1.5, 1.5) as (l,w,h) for each proposal. Consider theta or orientation to be 0 degrees for each proposal. 

2. **Training the CNN Network**.  
    Step 1 - I used Fast RCNN Network to train the network. Instead of regressing to 2D bounding boxes, I instead regress to obtain 3D bounding boxes. I followed the instructions from the paper[3D Object Proposals using Stereo Imagery for Accurate Object Class Detection](https://arxiv.org/pdf/1608.07711.pdf) to train the model. Source code for this can be downloaded from the author's website.  
    Step 2 - In the 3DOP model which needs to be downloaded from the author's website, change the .mat files for 3D bounding box proposals to the proposals that I generate. These .mat files can be downloaded from [here](https://drive.google.com/file/d/1I2Irsj-6dvHYUm82lmBfTn33hWyUxaW5/view?usp=sharing). The folder in 3DOP implementation where these files need to be unzipped is 3DOP_code_cuDNNv5/frcn-kitti/data/proposals/3DOP/car/mat/.  
    Step 3 - Train the network, and monitor it to see if the loss is reducing properly and if all the required parameters are set properly.
    
    

**Future Steps** -  
a. I would like to explore more efficient ways of generating the bounding box proposal.  
b. Try other networks like Faster RCNN, YOLO, SSD to generate 3D bounding box outputs.


**Accuracy results**:  
Car Detection 3D AP: Easy - 10.793%, Medium - 7.063%, Hard - 5.82%

I also checked results from state of the art 3DOP method which uses stereo images. I downloaded their trained caffe model and generated the results for that. Here are the results that I obtain for their method.  
Car Detection 3D AP: Easy - 7.42%, Medium - 6.26%, Hard - 6.52%

After reading some papers which uses monocular, stereo images or LIDAR point clouds, I believe that given the IoU threshold of 0.7 for cars, outputs from images although they seem visually accurate are not able to satisfy the IoU constraints of KITTI dataset. Output from LIDAR provides sparser but much more accurate depth point cloud.

**Output Images:**  
Some of the resulting output images can be downloaded from the link [here](https://drive.google.com/file/d/1m9RPrLMo4ewaO-qPSQhmiB4XWzUltElc/view?usp=sharing)
