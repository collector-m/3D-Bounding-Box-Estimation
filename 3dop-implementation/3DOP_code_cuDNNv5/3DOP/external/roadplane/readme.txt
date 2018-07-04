computeRoadPlaneTransformation() takes as input the disparity map of
the left image D (you can use for example
http://www.cvlibs.net/software/libelas/) as well as the intrinsics
vector in the order intrinsics=[fu fv cu cv baseline]. It outputs the
detected road area in the image as well as the rigid trafo between
camera and road plane coordinates in euclidean space.