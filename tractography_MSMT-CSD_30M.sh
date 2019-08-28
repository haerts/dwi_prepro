#!/bin/bash

################################################################################
#										 										                                       #
# This script will perform whole-brain probabilistic tractography and SIFT1 &  #
# SIFT2, for multi-shell DWI data.			 			 						                     #
#																				                                       #
# Written by Hannelore Aerts, Department of Data Analysis - Faculty of 		 	   #
# Psychology, Ghent University.													                       #
#																				                                       #
################################################################################

echo ">>> Checking files & folders"
dwi_results="$HOMEDIR/subjects/${subID}/dwi"


echo ">>> Probabilistic tractography"
# ACT; dynamic seeding
tckgen ${dwi_results}/wm_fod.mif ${dwi_results}/tracks_dynamic30M.tck -act ${dwi_results}/5tt.nii -backtrack -crop_at_gmwmi -seed_dynamic ${dwi_results}/wm_fod.mif -mask ${dwi_results}/mask_biasfield.nii -select 30000000 -quiet

echo ">>> SIFT1"
tcksift ${dwi_results}/tracks_dynamic30M.tck ${dwi_results}/wm_fod.mif ${dwi_results}/tracks_dynamic30M_sift1.tck -act ${dwi_results}/5tt.nii -term_number 7500000 -quiet
