#!/bin/bash

################################################################################
# This script will register your anatomical data to the individual diffusion
# space, by transforming the transform matrix in the T1 header, thereby
# preserving the spatial resolution of the anatomical images.
# Also, it will calculate the transformation from diffusion to MNI space (3MM).
#
# 062016 version:
#	  - Calculate inverse transform DWI=>T1 space to convert dwi_md map
#		to T1 space for USwLesion
#	  - Use FLIRT-FNIRT for registration to MNI
# 082016 version:
#   - Fixed minor bugs
# 112016 version:
#   - Only native transform DWI-T1; transform to MNI removed
#
# Written by Hannelore Aerts, Department of Data Analysis - Faculty of
# Psychology, Ghent University.
################################################################################

echo ">>> Checking files & folders"

  	dwi_results="$HOMEDIR/subjects/${subID}/dwi"
  	transf="${dwi_results}/transformations"
  	log_path="${dwi_results}/logs"
  	temp_path="${dwi_results}/temp"
  	config_path="$HOMEDIR/files"
  	mkdir -p ${transf}

echo ">>> Skullstrip T1"
 	 # Skullstrip T1
  	bet ${dwi_results}/T1.nii ${dwi_results}/T1_brain.nii -n -m -g -0.2 -f 0.2 -R
  	gunzip ${dwi_results}/T1_brain.nii.gz
  	gunzip ${dwi_results}/T1_brain_mask.nii.gz

 	  # Generate log of skullstrip
 	  slicer ${dwi_results}/T1.nii ${dwi_results}/T1_brain_mask.nii -s 2 -x 0.35 ${temp_path}/sla.png -x 0.45 ${temp_path}/slb.png -x 0.55 ${temp_path}/slc.png -x 0.65 ${temp_path}/sld.png -y 0.35 ${temp_path}/sle.png -y 0.45 ${temp_path}/slf.png -y 0.55 ${temp_path}/slg.png -y 0.65 ${temp_path}/slh.png -z 0.35 ${temp_path}/sli.png -z 0.45 ${temp_path}/slj.png -z 0.55 ${temp_path}/slk.png -z 0.65 ${temp_path}/sll.png
 	  pngappend ${temp_path}/sla.png + ${temp_path}/slb.png + ${temp_path}/slc.png + ${temp_path}/sld.png - ${temp_path}/sle.png + ${temp_path}/slf.png + ${temp_path}/slg.png + ${temp_path}/slh.png - ${temp_path}/sli.png + ${temp_path}/slj.png + ${temp_path}/slk.png + ${temp_path}/sll.png ${log_path}/T1_skullstrip.png
 	  rm ${temp_path}/*

  	# Naming files
  	t1_file="${dwi_results}/T1.nii"
  	t1_brain_file="${dwi_results}/T1_brain.nii"
  	dwi_distcor_file="${dwi_results}/dwi_distcor.nii"

  	# Make sure there is T1 file
  	if [ ! -f $t1_file ]; then
    	echo "Error: $t1_file not found!"
    	exit
  	fi
  	# Make sure there is T1 brain file
  	if [ ! -f $t1_brain_file ]; then
    	echo "Error: $t1_brain_file not found!"
    	exit
  	fi
  	# Make sure there is dwi_distcor
 	  if [ ! -f $dwi_distcor_file ]; then
    	echo "Error: $dwi_distcor_file not found!"
    	exit
 	  fi


echo ">>> DWI to T1 to DWI"
  	# Use epi_reg: uses FAST, BBR and FLIRT; slightly better than FLIRT
  	epi_reg --epi=${dwi_distcor_file} --t1=${t1_file} --t1brain=${t1_brain_file} --out=${transf}/dwi2anat
  	convert_xfm -inverse ${transf}/dwi2anat.mat -omat ${transf}/anat2dwi_fsl.mat
  	transformconvert ${transf}/anat2dwi_fsl.mat ${t1_file} ${dwi_distcor_file} flirt_import ${transf}/anat2dwi_mrtrix.mat -quiet
  	mrtransform ${t1_file} -linear ${transf}/anat2dwi_mrtrix.mat ${dwi_results}/T1_regis.nii -quiet

  	# Create log of registration
  	mrtransform ${dwi_results}/T1_regis.nii -template ${dwi_distcor_file} ${dwi_results}/T1_regis_vis.nii -quiet
  	slicer ${dwi_results}/T1_regis_vis.nii ${dwi_distcor_file} -s 2 -x 0.35 ${temp_path}/sla.png -x 0.45 ${temp_path}/slb.png -x 0.55 ${temp_path}/slc.png -x 0.65 ${temp_path}/sld.png -y 0.35 ${temp_path}/sle.png -y 0.45 ${temp_path}/slf.png -y 0.55 ${temp_path}/slg.png -y 0.65 ${temp_path}/slh.png -z 0.35 ${temp_path}/sli.png -z 0.45 ${temp_path}/slj.png -z 0.55 ${temp_path}/slk.png -z 0.65 ${temp_path}/sll.png
  	pngappend ${temp_path}/sla.png + ${temp_path}/slb.png + ${temp_path}/slc.png + ${temp_path}/sld.png + ${temp_path}/sle.png + ${temp_path}/slf.png + ${temp_path}/slg.png + ${temp_path}/slh.png + ${temp_path}/sli.png + ${temp_path}/slj.png + ${temp_path}/slk.png + ${temp_path}/sll.png ${temp_path}/anat2dwi1.png
  	slicer ${dwi_distcor_file} ${dwi_results}/T1_regis_vis.nii -s 2 -x 0.35 ${temp_path}/sla.png -x 0.45 ${temp_path}/slb.png -x 0.55 ${temp_path}/slc.png -x 0.65 ${temp_path}/sld.png -y 0.35 ${temp_path}/sle.png -y 0.45 ${temp_path}/slf.png -y 0.55 ${temp_path}/slg.png -y 0.65 ${temp_path}/slh.png -z 0.35 ${temp_path}/sli.png -z 0.45 ${temp_path}/slj.png -z 0.55 ${temp_path}/slk.png -z 0.65 ${temp_path}/sll.png
  	pngappend ${temp_path}/sla.png + ${temp_path}/slb.png + ${temp_path}/slc.png + ${temp_path}/sld.png + ${temp_path}/sle.png + ${temp_path}/slf.png + ${temp_path}/slg.png + ${temp_path}/slh.png + ${temp_path}/sli.png + ${temp_path}/slj.png + ${temp_path}/slk.png + ${temp_path}/sll.png ${temp_path}/anat2dwi2.png
  	pngappend ${temp_path}/anat2dwi1.png - ${temp_path}/anat2dwi2.png ${log_path}/anat2dwi.png
  	rm ${temp_path}/*
