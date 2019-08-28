#!/bin/bash

# For glioma patients only: Use normalized T1 image (from BCB norm) for 5TT segmentation.


# Before surgery -----------------------------------------------------------------------------#

#subj_path='/home/hannelore/Documents/ANALYSES/BTC_prepro/subjects/preop'
#data_path[0]=${subj_path}/PAT05T1
#data_path[1]=${subj_path}/PAT07T1
#data_path[2]=${subj_path}/PAT16T1
#data_path[3]=${subj_path}/PAT20T1
#data_path[4]=${subj_path}/PAT25T1
#data_path[5]=${subj_path}/PAT26T1
#data_path[6]=${subj_path}/PAT28T1

for subj_path in ${data_path[*]}
do
	subID=${subj_path: -7}

	echo ""
	echo ">>> Processing ${subID}"
	echo ""


# Step 1: copy normalized T1 image to dwi folder and transform to DWI space
mrtransform ${subj_path}/BCB_norm/Enantiomorphic${subID}.nii -linear ${subj_path}/dwi/transformations/anat2dwi_mrtrix.mat ${subj_path}/dwi/T1_norm_regis.nii -quiet

# Step 2: 5ttgen
5ttgen fsl -nocrop ${subj_path}/dwi/T1_norm_regis.nii ${subj_path}/dwi/5tt_norm.nii -force
5tt2vis ${subj_path}/dwi/5tt_norm.nii ${subj_path}/dwi/5tt_norm_vis.nii -quiet -force

#done


# After surgery -------------------------------------------------------------------------------#

#sub[0]="PAT05"
sub[1]="PAT07"
sub[2]="PAT16"
sub[3]="PAT20"
sub[4]="PAT25"
sub[5]="PAT26"
sub[6]="PAT28"

for subID in ${sub[*]}
do
	echo ">>> Processing $subID"

	preop_results=/home/hannelore/Documents/ANALYSES/BTC_prepro/subjects/preop/"$subID"T1
	postop_results=/home/hannelore/Documents/ANALYSES/BTC_prepro/subjects/postop/"$subID"T2

# Convert pre-op normalised T1 image to post-op T1 space
applywarp --in=${preop_results}/BCB_norm/Enantiomorphic"${subID}"T1.nii --ref=${postop_results}/dwi/T1_brain.nii --out=${postop_results}/dwi/T1_norm_t12t2.nii --warp=${postop_results}/FS/T12T2/y_anatt12t2.nii.gz

# Convert normalised T1 image to post-op DWI space
mrtransform ${postop_results}/dwi/T1_norm_t12t2.nii.gz -linear ${postop_results}/dwi/transformations/anat2dwi_mrtrix.mat ${postop_results}/dwi/T1_norm_regis_t12t2.nii -quiet -force

# 5ttgen
5ttgen fsl -nocrop ${postop_results}/dwi/T1_norm_regis_t12t2.nii ${postop_results}/dwi/5tt_norm.nii 
5tt2vis ${postop_results}/dwi/5tt_norm.nii ${postop_results}/dwi/5tt_norm_vis.nii -quiet 

done

