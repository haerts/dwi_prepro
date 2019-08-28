#!/bin/bash

################################################################################
#
# This script will convert your raw DICOM images to NIfTI format,
# using MRtrix3 "mrconvert".
#
# 052016 version:
#	  - Write shell information to log file and create variable indicating
# 		whether acquisition is single/multi-shell (15/06)
# 23082016 version:
#   - Cleaned up
#
# Written by Hannelore Aerts, Department of Data Analysis - Faculty of
# Psychology, Ghent University.
#
################################################################################

# Create the folders to store results
	dwi_results="$HOMEDIR/subjects/${subID}/dwi"
	log_path="${dwi_results}/logs"
	mkdir -p ${dwi_results}
	mkdir -p ${log_path}

echo ">>> Converting T1, DWI & DWI_PA images"
	# T1
	mrconvert $HOMEDIR/subjects/${subID}/RAWDATA/T1 ${dwi_results}/T1.nii -stride -1,+2,+3 -quiet

	# DWI
	mrconvert $HOMEDIR/subjects/${subID}/RAWDATA/DWI ${dwi_results}/dwi_raw.nii -export_grad_fsl ${dwi_results}/bvecs ${dwi_results}/bvals -stride -1,+2,+3,+4 -quiet
	mrconvert $HOMEDIR/subjects/${subID}/RAWDATA/DWI_PA ${dwi_results}/dwi_raw_PA.nii -stride -1,+2,+3,+4 -quiet

	# Write shell info to log file
	mrinfo $HOMEDIR/subjects/${subID}/RAWDATA/DWI -quiet -shells > ${log_path}/shells.txt
	mrinfo $HOMEDIR/subjects/${subID}/RAWDATA/DWI -quiet -shellcounts > ${log_path}/shellcounts.txt
