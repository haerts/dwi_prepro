#!/bin/bash

################################################################################
#
# This script will perform motion and eddy current correction of your DWI data,
# as well as bias field correction (required for SIFT + improves registration
# with T1
#
# (!!!) In case you have PA data, but only 1 AP b0 image, don't pay attention
# 	to the error (it will try to create mean of multiple b0 images)
#																	                                       #
# 042016 version
#	  - Strides adapted to -1,+2,+3,+4  (01/04/2016)
#	  - Eddy replaced by eddy_openmp (01/06/2016)
#	  - Adapted layout biasfield log (13/06/2016)
#     - Cleaned up (25/08/2016)
# 082017 version:
#	  - include dwidenoise & mrdegibbs
#																				                                       #
# Written by Hannelore Aerts, Department of Data Analysis - Faculty of
# Psychology, Ghent University.
#																				                                       #
################################################################################


# ">>> Checking files & folders"

# Making new folders
dwi_results="$HOMEDIR/subjects/${subID}/dwi"
temp_path="${dwi_results}/temp"
log_path="${dwi_results}/logs"
mkdir -p ${temp_path}
mkdir -p ${log_path}

# Make sure there is a dwi file
dwi_file="${dwi_results}/dwi_raw.nii"
if [ ! -f $dwi_file ]; then
  echo "Error: ${dwi_results}/dwi_raw.nii not found!"
  exit
fi

# Check whether there is a dwi_PA
dwirev_file="${dwi_results}/dwi_raw_PA.nii"

# Make sure there is a bvals
bval_file="${dwi_results}/bvals"
if [ ! -f $bval_file ]; then
  echo "Error: ${dwi_results}/bvals not found!"
  exit
fi

# Make sure there is a bvecs
bvec_file="${dwi_results}/bvecs"
if [ ! -f $bvec_file ]; then
  echo "Error: ${dwi_results}/bvecs not found!"
  exit
fi


echo ">>> Dwidenoise"
	dwidenoise ${dwi_results}/dwi_raw.nii ${dwi_results}/dwi_denoise.nii -quiet
	mrcalc ${dwi_results}/dwi_raw.nii ${dwi_results}/dwi_denoise.nii -subtract ${dwi_results}/noise_res.nii -quiet
	slicer ${dwi_results}/noise_res.nii -s 2 -x 0.35 ${temp_path}/sla.png -x 0.45 ${temp_path}/slb.png -x 0.55 ${temp_path}/slc.png -x 0.65 ${temp_path}/sld.png -y 0.35 ${temp_path}/sle.png -y 0.45 ${temp_path}/slf.png -y 0.55 ${temp_path}/slg.png -y 0.65 ${temp_path}/slh.png -z 0.35 ${temp_path}/sli.png -z 0.45 ${temp_path}/slj.png -z 0.55 ${temp_path}/slk.png -z 0.65 ${temp_path}/sll.png
  pngappend ${temp_path}/sla.png + ${temp_path}/slb.png + ${temp_path}/slc.png + ${temp_path}/sld.png - ${temp_path}/sle.png + ${temp_path}/slf.png + ${temp_path}/slg.png + ${temp_path}/slh.png - ${temp_path}/sli.png + ${temp_path}/slj.png + ${temp_path}/slk.png + ${temp_path}/sll.png ${log_path}/denoise_res.png
  rm ${temp_path}/*

	#dwidenoise ${dwi_results}/dwi_raw_PA.nii ${dwi_results}/dwi_denoise_PA.nii -quiet
  #better not do dwidenoise on short PA


echo ">>> MRdegibbs"
  mrdegibbs ${dwi_results}/dwi_denoise.nii ${dwi_results}/dwi_degibbs.nii -quiet
  mrdegibbs ${dwi_results}/dwi_raw_PA.nii ${dwi_results}/dwi_degibbs_PA.nii -quiet
  mrcalc ${dwi_results}/dwi_denoise.nii ${dwi_results}/dwi_degibbs.nii -subtract ${dwi_results}/degibbs_res.nii -quiet


echo ">>> Motion (and eddy current) correction DWI images"

  if [ ! -f $dwirev_file ]; then
    echo ">> No reverse phase encoding polarity images found. I will use FSL EDDY!"

		# Create mask for eddy
  	mrconvert ${dwi_results}/dwi_degibbs.nii -fslgrad ${dwi_results}/bvecs ${dwi_results}/bvals -quiet - | dwi2mask - - | maskfilter - dilate - | mrconvert - ${dwi_results}/mask_eddy.nii -datatype float32 -quiet

	  # Create log of mask for eddy
	  slicer ${dwi_results}/dwi_degibbs.nii ${dwi_results}/mask_eddy.nii -s 2 -x 0.35 ${temp_path}/sla.png -x 0.45 ${temp_path}/slb.png -x 0.55 ${temp_path}/slc.png -x 0.65 ${temp_path}/sld.png -y 0.35 ${temp_path}/sle.png -y 0.45 ${temp_path}/slf.png -y 0.55 ${temp_path}/slg.png -y 0.65 ${temp_path}/slh.png -z 0.35 ${temp_path}/sli.png -z 0.45 ${temp_path}/slj.png -z 0.55 ${temp_path}/slk.png -z 0.65 ${temp_path}/sll.png
  	pngappend ${temp_path}/sla.png + ${temp_path}/slb.png + ${temp_path}/slc.png + ${temp_path}/sld.png - ${temp_path}/sle.png + ${temp_path}/slf.png + ${temp_path}/slg.png + ${temp_path}/slh.png - ${temp_path}/sli.png + ${temp_path}/slj.png + ${temp_path}/slk.png + ${temp_path}/sll.png ${log_path}/mask_eddy.png
    rm ${temp_path}/*

  	# Construct a configuration file
  	echo -e "0  1 0 0.1\n0 -1 0 0.1\n" > ${dwi_results}/config.txt

  	# Generate configuration file for eddy - index referring to PE and bandwidth for each volume. In this particular case, we assume that every volume in the series has the same imaging parameters as the first of the reversed-PE pair. Therefore, every volume has an index of 1.
  	num_volumes=$( wc -w < ${dwi_results}/bvals )
  	start=1
  	end=$num_volumes

  	indx=""
  	for ((i=$start; i<=$end; i+=1)); do indx="$indx 1"; done
  	echo $indx > ${dwi_results}/index.txt

  	# Run eddy
		eddy_results="$dwi_results/eddy"
  	mkdir -p $eddy_results
  	eddy_openmp --imain=${dwi_results}/dwi_degibbs.nii --mask=${dwi_results}/mask_eddy.nii --index=${dwi_results}/index.txt --acqp=${dwi_results}/config.txt --bvecs=${dwi_results}/bvecs --bvals=${dwi_results}/bvals --out=${dwi_results}/dwi_eddy

  	# Reorganize results
  	mv ${dwi_results}/dwi_eddy.eddy* ${eddy_results}
  	mv ${dwi_results}/config.txt ${eddy_results}
  	mv ${dwi_results}/index.txt ${eddy_results}
  	gunzip ${dwi_results}/dwi_eddy.nii.gz
  	cp ${eddy_results}/dwi_eddy.eddy_rotated_bvecs ${dwi_results}/bvecs


 	else
    echo ">> Found the reverse phase encoding polarity images! I will use FSL TOPUP, APPLYTOPUP, & EDDY!"
	  # Extract all b0 images
	  dwiextract -bzero ${dwi_results}/dwi_degibbs.nii -fslgrad ${dwi_results}/bvecs ${dwi_results}/bvals ${dwi_results}/b0_AP.nii -quiet
	  mrmath ${dwi_results}/b0_AP.nii -axis 3 mean ${dwi_results}/b0_AP.nii -force -quiet
  	mrmath ${dwi_results}/dwi_degibbs_PA.nii -axis 3 mean ${dwi_results}/b0_PA.nii -quiet
	  mrcat ${dwi_results}/b0_AP.nii ${dwi_results}/b0_PA.nii - -axis 3 -quiet | mrconvert - ${dwi_results}/b0_all.nii -stride -1,+2,+3,+4 -quiet
	  rm ${dwi_results}/b0_AP.nii
	  rm ${dwi_results}/b0_PA.nii

	  # Construct a configuration file
  	echo -e "0  1 0 0.1\n0 -1 0 0.1\n" > ${dwi_results}/config.txt
	  config_file="$HOMEDIR/files/b02b0.cnf"

	  # Topup
	  topup --imain=${dwi_results}/b0_all.nii --datain=${dwi_results}/config.txt --out=${dwi_results}/topup --config=${config_file}
	  applytopup --imain=${dwi_results}/dwi_degibbs.nii --datain=${dwi_results}/config.txt --inindex=1 --topup=${dwi_results}/topup --out=${dwi_results}/applytopup --method=jac
	  mrconvert ${dwi_results}/applytopup.nii.gz ${dwi_results}/applytopup.nii -stride -1,+2,+3,+4 -quiet
	  rm ${dwi_results}/applytopup.nii.gz

  	# Brain mask for eddy
  	bet ${dwi_results}/applytopup.nii ${dwi_results}/mask_eddy.nii -f 0.2 -g 0.2 -n -m
  	mrconvert ${dwi_results}/mask_eddy_mask.nii.gz ${dwi_results}/mask_eddy.nii -datatype float32 -quiet
  	rm ${dwi_results}/mask_eddy_mask.nii.gz

  	# Create log of mask for eddy
  	slicer ${dwi_results}/applytopup.nii ${dwi_results}/mask_eddy.nii -s 2 -x 0.35 ${temp_path}/sla.png -x 0.45 ${temp_path}/slb.png -x 0.55 ${temp_path}/slc.png -x 0.65 ${temp_path}/sld.png -y 0.35 ${temp_path}/sle.png -y 0.45 ${temp_path}/slf.png -y 0.55 ${temp_path}/slg.png -y 0.65 ${temp_path}/slh.png -z 0.35 ${temp_path}/sli.png -z 0.45 ${temp_path}/slj.png -z 0.55 ${temp_path}/slk.png -z 0.65 ${temp_path}/sll.png
  	pngappend ${temp_path}/sla.png + ${temp_path}/slb.png + ${temp_path}/slc.png + ${temp_path}/sld.png - ${temp_path}/sle.png + ${temp_path}/slf.png + ${temp_path}/slg.png + ${temp_path}/slh.png - ${temp_path}/sli.png + ${temp_path}/slj.png + ${temp_path}/slk.png + ${temp_path}/sll.png ${log_path}/mask_eddy.png
    rm ${temp_path}/*

	  # Generate configuration file for eddy - index referring to PE and bandwidth for each volume. In this particular case, we assume that every volume in the series has the same imaging parameters as the first of the reversed-PE pair. Therefore, every volume has an index of 1.
  	num_volumes=$( wc -w < ${dwi_results}/bvals )
  	start=1
  	end=$num_volumes

	 	indx=""
  	for ((i=$start; i<=$end; i+=1)); do indx="$indx 1"; done
  	echo $indx > ${dwi_results}/index.txt

  	# Eddy
  	eddy_openmp --imain=${dwi_results}/dwi_degibbs.nii --mask=${dwi_results}/mask_eddy.nii --index=${dwi_results}/index.txt --acqp=${dwi_results}/config.txt --bvecs=${dwi_results}/bvecs --bvals=${dwi_results}/bvals --topup=${dwi_results}/topup --out=${dwi_results}/dwi_eddy

  	# Clean up results
  	topup_results="${dwi_results}/topup"
  	mkdir -p ${topup_results}
  	mv ${dwi_results}/applytopup.nii ${topup_results}/
  	mv ${dwi_results}/topup_* ${topup_results}/
  	mv ${dwi_results}/b0_all.topup_log ${topup_results}/
  	mv ${dwi_results}/config.txt ${topup_results}/

  	eddy_results="${dwi_results}/eddy"
  	mkdir -p ${eddy_results}
  	mv ${dwi_results}/dwi_eddy.eddy* ${eddy_results}/
    mv ${dwi_results}/index.txt ${eddy_results}/
    gunzip ${dwi_results}/dwi_eddy.nii.gz
  	rm ${dwi_results}/bvecs
    cp ${eddy_results}/dwi_eddy.eddy_rotated_bvecs ${dwi_results}/bvecs
    fi


echo ">>> Bias field correction DWI images"
	# Preparation
	bet ${dwi_results}/dwi_eddy.nii ${dwi_results}/mask_biasfield.nii -f 0.2 -g 0.2 -n -m
	mrconvert ${dwi_results}/mask_biasfield_mask.nii.gz ${dwi_results}/mask_biasfield.nii -datatype float32 -quiet
	rm ${dwi_results}/mask_biasfield_mask.nii.gz

	# Create log of mask for biasfield
	slicer ${dwi_results}/dwi_eddy.nii ${dwi_results}/mask_biasfield.nii -s 2 -x 0.35 ${temp_path}/sla.png -x 0.45 ${temp_path}/slb.png -x 0.55 ${temp_path}/slc.png -x 0.65 ${temp_path}/sld.png -y 0.35 ${temp_path}/sle.png -y 0.45 ${temp_path}/slf.png -y 0.55 ${temp_path}/slg.png -y 0.65 ${temp_path}/slh.png -z 0.35 ${temp_path}/sli.png -z 0.45 ${temp_path}/slj.png -z 0.55 ${temp_path}/slk.png -z 0.65 ${temp_path}/sll.png
  pngappend ${temp_path}/sla.png + ${temp_path}/slb.png + ${temp_path}/slc.png + ${temp_path}/sld.png - ${temp_path}/sle.png + ${temp_path}/slf.png + ${temp_path}/slg.png + ${temp_path}/slh.png - ${temp_path}/sli.png + ${temp_path}/slj.png + ${temp_path}/slk.png + ${temp_path}/sll.png ${log_path}/mask_biasfield.png
  rm ${temp_path}/*

	# Mask b0 AP images
	dwiextract -bzero ${dwi_results}/dwi_eddy.nii -fslgrad ${dwi_results}/bvecs ${dwi_results}/bvals -quiet - | mrcalc - ${dwi_results}/mask_biasfield.nii -mult ${dwi_results}/b0_AP_eddycor.nii -quiet
	mrmath ${dwi_results}/b0_AP_eddycor.nii -axis 3 mean ${dwi_results}/b0_AP_eddycor.nii -force -quiet

	# Run FAST
	fast_results="${dwi_results}/fast"
  mkdir -p $fast_results
  fast -t 2 -o ${fast_results}/fast -n 3 -b ${dwi_results}/b0_AP_eddycor.nii
  mrcalc ${dwi_results}/dwi_eddy.nii ${fast_results}/fast_bias.nii.gz -div ${dwi_results}/dwi_distcor.nii -quiet
