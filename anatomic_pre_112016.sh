#!/bin/bash

################################################################################
#
# This script will perform 5 tissue type (5tt) segmentation and create a map
# of the gm-wm interface (gmwmi) needed for ACT.
#
# 082016 version:
#		- Cleaned up
# 112016 version:
#		- Don't use USwL for meningioma patients (for now...)
#
# Written by Hannelore Aerts, Department of Data Analysis - Faculty of
# Psychology, Ghent University.
#
################################################################################

# ">>> Checking files & folders"
	dwi_results="$HOMEDIR/subjects/${subID}/dwi"
	transf="${dwi_results}/transformations"
	temp_path="${dwi_results}/temp"
	log_path="${dwi_results}/logs"

	# Make sure there is an anatomical
	t1_file="${dwi_results}/T1_regis.nii"
	if [ ! -f $t1_file ]; then
		echo "Error: ${dwi_results}/T1_regis.nii not found!"
    	exit
	fi

# ">>> Preprocessing anatomical images: 5tt segmentation"
	5ttgen fsl -nocrop ${dwi_results}/T1_regis.nii ${dwi_results}/5tt.nii
	5tt2gmwmi ${dwi_results}/5tt.nii ${dwi_results}/gmwmi.nii -quiet
	mrtransform ${dwi_results}/gmwmi.nii -template ${dwi_results}/T1_regis.nii ${dwi_results}/gmwmi_vis.nii -quiet
	5tt2vis ${dwi_results}/5tt.nii ${dwi_results}/5tt_vis_tmp.nii -quiet
	mrtransform ${dwi_results}/5tt_vis_tmp.nii -template ${dwi_results}/T1_regis.nii ${dwi_results}/5tt_vis.nii -quiet
	rm ${dwi_results}/5tt_vis_tmp.nii

	# Generate log of gmwmi
	slicer ${dwi_results}/T1_regis.nii ${dwi_results}/gmwmi_vis.nii -s 2 -x 0.35 ${temp_path}/sla.png -x 0.45 ${temp_path}/slb.png -x 0.55 ${temp_path}/slc.png -x 0.65 ${temp_path}/sld.png -y 0.35 ${temp_path}/sle.png -y 0.45 ${temp_path}/slf.png -y 0.55 ${temp_path}/slg.png -y 0.65 ${temp_path}/slh.png -z 0.35 ${temp_path}/sli.png -z 0.45 ${temp_path}/slj.png -z 0.55 ${temp_path}/slk.png -z 0.65 ${temp_path}/sll.png
	pngappend ${temp_path}/sla.png + ${temp_path}/slb.png + ${temp_path}/slc.png + ${temp_path}/sld.png - ${temp_path}/sle.png + ${temp_path}/slf.png + ${temp_path}/slg.png + ${temp_path}/slh.png - ${temp_path}/sli.png + ${temp_path}/slj.png + ${temp_path}/slk.png + ${temp_path}/sll.png ${log_path}/gmwmi.png
	rm ${temp_path}/*

	# Generate log of 5tt2vis
	slicer ${dwi_results}/5tt_vis.nii -s 2 -x 0.35 ${temp_path}/sla.png -x 0.45 ${temp_path}/slb.png -x 0.55 ${temp_path}/slc.png -x 0.65 ${temp_path}/sld.png -y 0.35 ${temp_path}/sle.png -y 0.45 ${temp_path}/slf.png -y 0.55 ${temp_path}/slg.png -y 0.65 ${temp_path}/slh.png -z 0.35 ${temp_path}/sli.png -z 0.45 ${temp_path}/slj.png -z 0.55 ${temp_path}/slk.png -z 0.65 ${temp_path}/sll.png
	pngappend ${temp_path}/sla.png + ${temp_path}/slb.png + ${temp_path}/slc.png + ${temp_path}/sld.png - ${temp_path}/sle.png + ${temp_path}/slf.png + ${temp_path}/slg.png + ${temp_path}/slh.png - ${temp_path}/sli.png + ${temp_path}/slj.png + ${temp_path}/slk.png + ${temp_path}/sll.png ${log_path}/5ttvis.png
	rm ${temp_path}/*

	#remove temp files
	rm ${dwi_results}/gmwmi_vis.nii
	rm ${dwi_results}/5tt_vis.nii
