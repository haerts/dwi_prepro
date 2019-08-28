#!/bin/bash

# =============================================================================
# Specify data:
# =============================================================================

main='/home/hannelore/Documents/ANALYSES/BTC_prepro'
input='/home/hannelore/Documents/ANALYSES/BTC_prepro/subjects/preop'

#data_path[0]="${input}/CON01T1"
#data_path[1]="${input}/CON02T1"
#data_path[2]="${input}/CON03T1"
#data_path[3]="${input}/CON04T1"
#data_path[4]="${input}/CON05T1"
#data_path[5]="${input}/CON06T1"
#data_path[6]="${input}/CON07T1"
#data_path[7]="${input}/CON08T1"
#data_path[8]="${input}/CON09T1"
#data_path[9]="${input}/CON10T1"
#data_path[10]="${input}/CON11T1"

#data_path[11]="${input}/PAT01T1"
#data_path[12]="${input}/PAT02T1"
#data_path[13]="${input}/PAT03T1"
#data_path[14]="${input}/PAT06T1"
#data_path[15]="${input}/PAT08T1"
#data_path[16]="${input}/PAT10T1"
#data_path[17]="${input}/PAT11T1" 
#data_path[18]="${input}/PAT13T1"
#data_path[19]="${input}/PAT14T1"
#data_path[20]="${input}/PAT15T1"
#data_path[21]="${input}/PAT17T1"
#data_path[22]="${input}/PAT19T1"
#data_path[23]="${input}/PAT23T1"
#data_path[24]="${input}/PAT24T1"

#data_path[25]="${input}/PAT05T1"
data_path[26]="${input}/PAT07T1"
data_path[27]="${input}/PAT16T1"
data_path[28]="${input}/PAT20T1"
#data_path[29]="${input}/PAT22T1"
#data_path[30]="${input}/PAT25T1"
#data_path[31]="${input}/PAT26T1"
#data_path[32]="${input}/PAT27T1"
#data_path[33]="${input}/PAT28T1"
#data_path[34]="${input}/PAT29T1"


# =============================================================================
# Part 1: Compute SC and distance matrix
# =============================================================================
part1=1
if [ $part1 == 1 ]; then
	echo "Compute SC and distance matrix"

config_folder='/home/hannelore/mrtrix3/share/mrtrix3/labelconvert'
colorLUT_folder='/usr/local/freesurfer'

for subj_path in ${data_path[*]}
do
	subID=${subj_path: -7}

	echo ""
	echo ">>> Processing ${subID}"
	echo ""

	# Checking files & folders
	FS_results="${subj_path[$i]}/FS"
	dwi_results="${subj_path[$i]}/dwi"
    transf="${dwi_results}/transformations"


	echo ">>> Transform original T1 to FS T1"
	mri_convert --in_type mgz --out_type nii --input_volume ${FS_results}/orig.mgz  --output_volume ${FS_results}/orig.nii.gz
	mri_convert --in_type mgz --out_type nii --input_volume ${FS_results}/rawavg.mgz  --output_volume ${FS_results}/rawavg.nii.gz
	mrconvert ${FS_results}/orig.nii.gz ${FS_results}/orig_strcor.nii.gz -stride -1,+2,+3 -quiet
	mrconvert ${FS_results}/rawavg.nii.gz ${FS_results}/rawavg_strcor.nii.gz -stride -1,+2,+3 -quiet
	rm ${FS_results}/orig.nii.gz
	rm ${FS_results}/rawavg.nii.gz
	tkregister2 --mov ${FS_results}/orig_strcor.nii.gz --targ ${FS_results}/rawavg_strcor.nii.gz --regheader --reg jumk --fslregout ${transf}/FS2anat.mat --noedit
	convert_xfm -omat ${transf}/anat2FS.mat -inverse ${transf}/FS2anat.mat


    echo ">>> Transform FS parcellation to DWI space"
	mri_convert --in_type mgz --out_type nii --input_volume ${FS_results}/aparc+aseg.mgz  --output_volume ${dwi_results}/parc_FS.nii.gz
	mrconvert ${dwi_results}/parc_FS.nii.gz ${dwi_results}/parc_FS.nii.gz -stride -1,+2,+3 -force -quiet

	flirt -ref ${dwi_results}/T1_brain.nii -in ${dwi_results}/parc_FS.nii.gz -out ${dwi_results}/parc_T1.nii.gz -applyxfm -init ${transf}/FS2anat.mat -interp nearestneighbour

	applywarp -i ${dwi_results}/parc_T1.nii.gz -o ${dwi_results}/parc_DWI.nii.gz -r ${dwi_results}/b0_AP_eddycor.nii --premat=${transf}/anat2dwi_fsl.mat --interp=nn

	labelconvert ${dwi_results}/parc_DWI.nii.gz ${colorLUT_folder}/FreeSurferColorLUT.txt ${config_folder}/fs_default_TVB.txt  ${dwi_results}/parc_DWI_final.nii.gz -quiet
	#gunzip ${dwi_results}/parc_DWI_final.nii.gz


  	echo ">>> Create SC matrix"
	tck2connectome ${dwi_results}/tracks_dynamic30M_sift1.tck ${dwi_results}/nodes68.nii ${dwi_results}/SCcount_sift1_30M_68.csv -zero_diagonal #-out_assignments ${dwi_results}/tracks_assignments.txt

	tck2connectome ${dwi_results}/tracks_dynamic30M_sift1.tck ${dwi_results}/nodes68.nii ${dwi_results}/SCcount_sift1_30M_68.csv -zero_diagonal 

	echo ">>> Create distance matrix"
  	tck2connectome ${dwi_results}/tracks_dynamic30M_sift1.tck ${dwi_results}/parc68_DWI.nii ${dwi_results}/SCdist_sift1_30M_68.csv -scale_length -stat_edge mean

  	echo ">>> Streamtubes for visualization"
	connectome2tck ${dwi_results}/tracks_dynamic30M_sift1.tck ${dwi_results}/tracks_assignments.txt ${dwi_results}/tracks_streamlines -exemplars ${dwi_results}/parc68_DWI.nii -files single

done
else
	echo " "
fi



# =============================================================================
# Part 2: transform .csv to .mat  
# =============================================================================
part2=0
if [ $part2 == 1 ]; then
	echo "Transform .csv to .mat"

for subj_path in ${data_path[*]}
do
	subID=${subj_path: -7}

	echo ""
	echo ">>> Processing ${subID}"
	echo ""

	dwi_results="${subj_path}/dwi"
	matlab -nodesktop -r "cd ${dwi_results}; M=dlmread('SCcount_sift1_30M_68.csv'); SC=M + M'; save('SCcount_sift1_30M_68', 'SC');exit;"
# D=dlmread('SCdist.csv'); SC_dist=D + D'; save('SCdist', 'SC_dist'); exit;"

done
else
	echo " "
fi


# =============================================================================
# Part 3: Create TVB input   
# =============================================================================
part3=1
if [ $part3 == 1 ]; then
	echo "Run 'Generate_TVBii_Input.m' script in matlab."
else
	echo " "
fi







