## 3D Object Proposals (3DOP)
This is an implementation of the algorithms described in

3D Object Proposals for Accurate Object Class Detection. 
Xiaozhi Chen*, Kaustav Kunku*, Yukun Zhu, Andrew Berneshawi, Huimin Ma, Sanja Fidler and Raquel Urtasun. NIPS, 2015.
* Denotes equal contribution

**Project page:** http://www.cs.toronto.edu/~objprop3d/

### License

3D Object Proposals (3DOP) is copyright by Xiaozhi Chen, Kaustav Kunku, Yukun Zhu, Andrew Berneshawi,
Huimin Ma, Sanja Fidler and Raquel Urtasun. It is released for personal or
academic use only. Any commercial use is strictly prohibited except by explicit
permission by the authors. For more information on commercial use, contact
Raquel Urtasun.

The authors of this software and corresponding paper assume no liability for
its use and by using this software you agree to these terms.

### Precomputed Results

We provide following precomputed models and results on our project page: http://www.cs.toronto.edu/~objprop3d/
- Class-dependent 2D/3D proposals for KITTI training set
- Class-independent 2D/3D proposals for KITTI training set
- 2D/3D detection results using class-dependent 3DOP on KITTI validation set
- 2D/3D detection results using class-independent 3DOP on KITTI validation set
- CNN models trained with class-dependent 3DOP on KITTI training set
- CNN models trained with class-independent 3DOP on KITTI training set
- Disparity computed by SPS-stereo for KITTI training and test sets
- Road planes for KITTI training and test sets

### Compute Proposals

Please refer to `./3DOP/demo_3dop.m` for training/testing/evaluation of the proposals.

### Object Detection Networks

Detection code is under `./frcn-kitti/`
This implementation is built on Fast R-CNN (https://github.com/rbgirshick/fast-rcnn).

1. Build Caffe

Please follow Fast R-CNN (https://github.com/rbgirshick/fast-rcnn) to compile caffe and pycaffe.
**Note**:
- A GPU with 12G memory is required.
- Caffe must be built with CUDNN v2 (or higher), otherwise the networks can not fit in GPU memory.
- Caffe must be built with support for Python layers.

2. Build the Cython modules

```shell
cd ./frcn-kitti/lib
make
```

3. Prepare data

- KITTI images are supposed to be placed unber `./frcn-kitti/data/kitti/object/`
- 3D object proposals are supposed to be placed under `./frcn-kitti/data/proposals/`

4. Download pre-trained ImageNet models
```shell
cd ./frcn-kitti
./data/scripts/fetch_imagenet_models.sh
```

5. Compile KITTI evaluation code
```shell
cd ./frcn-kitti/kitti/eval/cpp
g++ evaluate_object.cpp -o evaluate_object
```

6. Training & testing

Please refer to `./frcn-kitti/demo.sh` for training/testing of the detection networks.

### Citation
If you use the 3D object proposals, please consider citing:

@inproceedings{3dopNIPS15,
  title = {3D Object Proposals for Accurate Object Class Detection},
  author = {Xiaozhi Chen and Kaustav Kundu and Yukun Zhu and Andrew Berneshawi and Huimin Ma and Sanja Fidler and Raquel Urtasun},
  booktitle = {NIPS},
  year = {2015}}

and the SPS-stereo paper:

@inproceedings{YamaguchiECCV04,
  title = {Efficient Joint Segmentation, Occlusion Labeling, Stereo and Flow Estimation},
  author = {K. Yamaguchi and D. McAllester and R. Urtasun},
  booktitle = {ECCV},
  year = {2014}
}

and the following paper (the S-SVM code adopts this implementation):

@inproceedings{SchwingICCV2013,
  author = {A.~G. Schwing and S. Fidler and M. Pollefeys and R. Urtasun},
  title = {{Box In the Box: Joint 3D Layout and Object Reasoning from Single Images}},
  booktitle = {Proc. ICCV},
  year = {2013},
}

If you use the frcn-kitti code, please also cite:

@inproceedings{girshickICCV15fastrcnn,
  Author = {Ross Girshick},
  Title = {Fast R-CNN},
  Booktitle = {International Conference on Computer Vision ({ICCV})},
  Year = {2015}
}
