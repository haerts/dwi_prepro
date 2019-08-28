#!/bin/bash

# =============================================================================
# Specify data:
# =============================================================================
config_folder='/home/hannelore/mrtrix3/share/mrtrix3/labelconvert'
colorLUT_folder='/usr/local/freesurfer'
input='/home/hannelore/Documents/ANALYSES/BTC_prepro/subjects/postop'

#=============================================================================
# Part 1: FS parcellation for controls and some meningioma patients 
# 	(ie for those subjects for which I have run FS on post-op data,
#	being the ones with little residual lesion after surgery)
#=============================================================================
part1=0
if [ $part1 == 1 ]; then
	echo "***********************************************************************"
	echo " Parcellation of controls and some meningioma pts"
	echo "***********************************************************************"

#data_path[0]="${input}/CON02T2"
#data_path[1]="${input}/CON03T2"
data_path[2]="${input}/CON04T2"
#data_path[3]="${input}/CON05T2"
#data_path[4]="${input}/CON06T2"
#data_path[5]="${input}/CON07T2"
#data_path[6]="${input}/CON08T2"
#data_path[7]="${input}/CON09T2"
#data_path[8]="${input}/CON10T2"
#data_path[9]="${input}/CON11T2"
#data_path[10]="${input}/PAT01T2"
#data_path[11]="${input}/PAT06T2"
#data_path[12]="${input}/PAT08T2"
#data_path[13]="${input}/PAT10T2"
#data_path[14]="${input}/PAT13T2"
#data_path[15]="${input}/PAT15T2"
#data_path[16]="${input}/PAT17T2"
#data_path[17]="${input}/PAT24T2"

for subj_path in ${data_path[*]}
do
	subID=${subj_path: -7}

	echo ""
	echo ">>> Processing ${subID}"
	echo ""

	# Checking files & folders
	FS_results="${subj_path[$i]}/FS/mri"
	dwi_results="${subj_path[$i]}/dwi"
  	transf="${dwi_results}/transformations"

	echo ""
	echo ">>> Transform original T1 to FS T1"
	echo ""
	mri_convert --in_type mgz --out_type nii --input_volume ${FS_results}/orig.mgz  --output_volume ${FS_results}/orig.nii.gz
	mri_convert --in_type mgz --out_type nii --input_volume ${FS_results}/rawavg.mgz  --output_volume ${FS_results}/rawavg.nii.gz
	mrconvert ${FS_results}/orig.nii.gz ${FS_results}/orig_strcor.nii.gz -stride -1,+2,+3 -quiet
	mrconvert ${FS_results}/rawavg.nii.gz ${FS_results}/rawavg_strcor.nii.gz -stride -1,+2,+3 -quiet
	rm ${FS_results}/orig.nii.gz
	rm ${FS_results}/rawavg.nii.gz
	tkregister2 --mov ${FS_results}/orig_strcor.nii.gz --targ ${FS_results}/rawavg_strcor.nii.gz --regheader --reg jumk --fslregout ${transf}/FS2anat.mat --noedit
	convert_xfm -omat ${transf}/anat2FS.mat -inverse ${transf}/FS2anat.mat

	echo ""
  echo ">>> Transform FS parcellation to DWI space"
	echo ""
	mri_convert --in_type mgz --out_type nii --input_volume ${FS_results}/aparc+aseg.mgz  --output_volume ${dwi_results}/parc_FS.nii.gz
	mrconvert ${dwi_results}/parc_FS.nii.gz ${dwi_results}/parc_FS.nii.gz -stride -1,+2,+3 -force -quiet

	flirt -ref ${dwi_results}/T1_brain.nii -in ${dwi_results}/parc_FS.nii.gz -out ${dwi_results}/parc_T1.nii.gz -applyxfm -init ${transf}/FS2anat.mat -interp nearestneighbour

	applywarp -i ${dwi_results}/parc_T1.nii.gz -o ${dwi_results}/parc_DWI.nii.gz -r ${dwi_results}/b0_AP_eddycor.nii --premat=${transf}/anat2dwi_fsl.mat --interp=nn

	labelconvert ${dwi_results}/parc_DWI.nii.gz ${colorLUT_folder}/FreeSurferColorLUT.txt ${config_folder}/fs_default_TVB.txt  ${dwi_results}/nodes68.nii.gz -quiet
	gunzip ${dwi_results}/nodes68.nii.gz

	label2colour ${dwi_results}/nodes68.nii ${dwi_results}/nodes_color68.nii -lut ${config_folder}/fs_default_TVB.txt

done
else
	echo " "
fi


#=============================================================================
# Part 2: FS parcellation for glioma pts using their pre-op parcellation.
#=============================================================================

part2=0
if [ $part2 == 1 ]; then
	echo "***********************************************************************"
	echo "Parcellation of glioma pts using their pre-op parcellation."
	echo "***********************************************************************"

	#sub[0]="PAT05"
	#sub[1]="PAT07"
	#sub[2]="PAT16"
	#sub[3]="PAT20"
	#sub[4]="PAT25"
	sub[5]="PAT26"
	sub[6]="PAT28"

for subID in ${sub[*]}
do
	echo ">>> Processing $subID"

	preop_results=/home/hannelore/Documents/ANALYSES/BTC_prepro/subjects/preop/"$subID"T1
	postop_results=/home/hannelore/Documents/ANALYSES/BTC_prepro/subjects/postop/"$subID"T2

	T1_t1=${preop_results}/dwi/T1_brain.nii
	T1_t2=${postop_results}/dwi/T1_brain.nii
	FS_results=${postop_results}/FS
	dwi_results=${postop_results}/dwi
	mkdir -p $FS_results/T12T2

	# Get transformation from T1 t1 to t2
	flirt -ref $T1_t2 -in $T1_t1 -out ${FS_results}/T12T2/anat_t12t2_flirt.nii.gz -omat ${FS_results}/T12T2/anat_t12t2_flirt.mat
	fnirt --in=$T1_t1 --ref=${T1_t2} --refmask=${dwi_results}/T1_brain_mask.nii --config=/home/hannelore/Documents/ANALYSES/BTC_prepro/scripts/FNIRT_options.cnf --inmask=${preop_results}/dwi/T1_brain_mask.nii --aff=${FS_results}/T12T2/anat_t12t2_flirt.mat --iout=${FS_results}/T12T2/anat_t12t2_fnirt.nii.gz --fout=${FS_results}/T12T2/y_anatt12t2.nii.gz --cout=${FS_results}/T12T2/anat_t12t2_warpcoef.nii.gz

	# Apply this transformation to t1 parcellation
	applywarp --in=${preop_results}/dwi/parc68_T1.nii.gz --ref=$T1_t2 --out=${FS_results}/T12T2/parc_T1_t12t2.nii.gz --warp=${FS_results}/T12T2/y_anatt12t2.nii.gz --interp=nn

	# Convert parcellation to DWI space
	applywarp -i ${FS_results}/T12T2/parc_T1_t12t2.nii.gz -o ${dwi_results}/parc68_DWI.nii.gz -r ${dwi_results}/b0_AP_eddycor.nii --premat=${dwi_results}/transformations/anat2dwi_fsl.mat --interp=nn

	labelconvert ${dwi_results}/parc68_DWI.nii.gz ${colorLUT_folder}/FreeSurferColorLUT.txt ${config_folder}/fs_default_TVB.txt ${dwi_results}/nodes68.nii.gz -quiet
	gunzip ${dwi_results}/nodes68.nii.gz

	label2colour ${dwi_results}/nodes68.nii ${dwi_results}/nodes68_color.nii -lut ${config_folder}/fs_default_TVB.txt

done
else
	echo " "
fi


#=============================================================================
# Part 3: FS parcellation for meningioma pts after manual edits
#=============================================================================
part3=0
if [ $part3 == 1 ]; then
	echo "***********************************************************************"
	echo " Compute SC and distance matrix for meningioma pts after manual edits"
	echo "***********************************************************************"

data_path[0]="${input}/PAT02T2"
#data_path[1]="${input}/PAT03T2"

for subj_path in ${data_path[*]}
do
	subID=${subj_path: -7}

	echo ""
	echo ">>> Processing ${subID}"
	echo ""

	# Checking files & folders
	FS_results="${subj_path[$i]}/FS/mri"
	FS_norm_results="${subj_path[$i]}/FS_norm/mri"
	dwi_results="${subj_path[$i]}/dwi"
  	transf="${dwi_results}/transformations"

	echo ""
	echo ">>> Transform original T1 to FS T1"
	echo ""
	mri_convert --in_type mgz --out_type nii --input_volume ${FS_results}/orig.mgz  --output_volume ${FS_results}/orig.nii.gz
	mri_convert --in_type mgz --out_type nii --input_volume ${FS_results}/rawavg.mgz  --output_volume ${FS_results}/rawavg.nii.gz
	mrconvert ${FS_results}/orig.nii.gz ${FS_results}/orig_strcor.nii.gz -stride -1,+2,+3 -quiet
	mrconvert ${FS_results}/rawavg.nii.gz ${FS_results}/rawavg_strcor.nii.gz -stride -1,+2,+3 -quiet
	rm ${FS_results}/orig.nii.gz
	rm ${FS_results}/rawavg.nii.gz
	tkregister2 --mov ${FS_results}/orig_strcor.nii.gz --targ ${FS_results}/rawavg_strcor.nii.gz --regheader --reg jumk --fslregout ${transf}/FS2anat.mat --noedit
	convert_xfm -omat ${transf}/anat2FS.mat -inverse ${transf}/FS2anat.mat

	echo ""
  echo ">>> Transform FS parcellation to DWI space"
	echo ""
	mri_convert --in_type mgz --out_type nii --input_volume ${FS_norm_results}/aparc+aseg.mgz  --output_volume ${dwi_results}/parc_FS.nii.gz
	mrconvert ${dwi_results}/parc_FS.nii.gz ${dwi_results}/parc_FS.nii.gz -stride -1,+2,+3 -force -quiet

	flirt -ref ${dwi_results}/T1_brain.nii -in ${dwi_results}/parc_FS.nii.gz -out ${dwi_results}/parc_T1.nii.gz -applyxfm -init ${transf}/FS2anat.mat -interp nearestneighbour

	applywarp -i ${dwi_results}/parc_T1.nii.gz -o ${dwi_results}/parc_DWI.nii.gz -r ${dwi_results}/b0_AP_eddycor.nii --premat=${transf}/anat2dwi_fsl.mat --interp=nn

	labelconvert ${dwi_results}/parc_DWI.nii.gz ${colorLUT_folder}/FreeSurferColorLUT.txt ${config_folder}/fs_default_TVB.txt  ${dwi_results}/nodes68.nii.gz -quiet
	gunzip ${dwi_results}/nodes68.nii.gz

	label2colour ${dwi_results}/nodes68.nii ${dwi_results}/nodes68_color.nii -lut ${config_folder}/fs_default_TVB.txt

done
else
	echo " "
fi

#=============================================================================
# Part 4: Compute SC and distance matrix for all subjects
#=============================================================================
part4=1
if [ $part4 == 1 ]; then
	echo "***********************************************************************"
	echo "Compute SC and distance matrices."
	echo "***********************************************************************"

#data_path[0]="${input}/CON02T2"
#data_path[1]="${input}/CON03T2"
#data_path[2]="${input}/CON04T2"
#data_path[3]="${input}/CON05T2"
#data_path[4]="${input}/CON06T2"
#data_path[5]="${input}/CON07T2"
#data_path[6]="${input}/CON08T2"
#data_path[7]="${input}/CON09T2"
#data_path[8]="${input}/CON10T2"
#data_path[9]="${input}/CON11T2"
#data_path[10]="${input}/PAT01T2"
#data_path[11]="${input}/PAT06T2"
#data_path[12]="${input}/PAT08T2"
#data_path[13]="${input}/PAT10T2"
#data_path[14]="${input}/PAT13T2"
#data_path[15]="${input}/PAT15T2"
#data_path[16]="${input}/PAT17T2"
#data_path[17]="${input}/PAT24T2"

data_path[18]="${input}/PAT05T2"
data_path[19]="${input}/PAT07T2"
data_path[20]="${input}/PAT16T2"
data_path[21]="${input}/PAT20T2"
data_path[22]="${input}/PAT25T2"
data_path[23]="${input}/PAT26T2"
data_path[24]="${input}/PAT28T2"

#data_path[25]="${input}/PAT02T2"
#data_path[26]="${input}/PAT03T2"

for subj_path in ${data_path[*]}
do
	subID=${subj_path: -7}

	echo ""
	echo ">>> Processing ${subID}"
	echo ""

	# Checking files & folders
	dwi_results="${subj_path[$i]}/dwi"

	tck2connectome ${dwi_results}/tracks_dynamic30M_sift1.tck ${dwi_results}/nodes68.nii ${dwi_results}/SCcount_sift1_30M_68.csv -zero_diagonal #-out_assignments ${dwi_results}/tracks_assignments.txt

	tck2connectome ${dwi_results}/tracks_dynamic30M_sift1.tck ${dwi_results}/nodes68.nii ${dwi_results}/SCdist_sift1_30M_68.csv -scale_length -stat_edge mean

	connectome2tck ${dwi_results}/tracks_dynamic30M_sift1.tck ${dwi_results}/tracks_assignments.txt ${dwi_results}/tracks_streamlines.tck -exemplars ${dwi_results}/nodes68.nii -files single

	matlab -nodesktop -r "cd ${dwi_results}; M=dlmread('SCcount_sift1_30M_68.csv'); SC=M + M'; save('SCcount_sift1_30M_68', 'SC'); exit;"
#D=dlmread('SCdist_sift1_30M_68.csv'); SC_dist=D + D'; save('SCdist_sift1_30M_68', 'SC_dist'); exit;"

done
else
	echo " "
fi

