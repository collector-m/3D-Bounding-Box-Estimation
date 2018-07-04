# Demo scripts for running Fast R-CNN with 3D Object Proposals (3DOP)
# VGG16 model is used

gpu_id=0

# ---------------------------------------------------------------------
# proposals: class-dependent 3DOP, top 2K proposals used
# category: car
# the model used in the NIPS paper, i.e., Fast R-CNN with orientation loss and contextual branch
#./kitti/scripts/kitti_car_vgg16.sh --cpu
./kitti/scripts/kitti_car_vgg16.sh $gpu_id 3DOP_top2K

# the original Fast R-CNN model
#./kitti/scripts/kitti_car_vgg16_frcn.sh $gpu_id 3DOP_top2K_no_ort

# Fast R-CNN with orientation loss
#./kitti/scripts/kitti_car_vgg16_ort.sh $gpu_id 3DOP_top2K


# category: pedestrian and cyclist
# the model used in the NIPS paper, i.e., Fast R-CNN with orientation loss and contextual branch
#./kitti/scripts/kitti_ped_cyc_vgg16.sh $gpu_id 3DOP_top2K

# the original Fast R-CNN model
#./kitti/scripts/kitti_ped_cyc_vgg16_frcn.sh $gpu_id 3DOP_top2K_no_ort

# Fast R-CNN with orientation loss
#./kitti/scripts/kitti_ped_cyc_vgg16_ort.sh $gpu_id 3DOP_top2K


# ---------------------------------------------------------------------
# proposals: class-independent 3DOP, top 2K proposals used
# category: car
# the model used in the NIPS paper, i.e., Fast R-CNN with orientation loss and contextual branch
#./kitti/scripts/kitti_car_vgg16.sh $gpu_id 3DOP_generic_top2K

# category: pedestrian and cyclist
# the model used in the NIPS paper, i.e., Fast R-CNN with orientation loss and contextual branch
#./kitti/scripts/kitti_ped_cyc_vgg16.sh $gpu_id 3DOP_generic_top2K


