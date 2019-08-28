#!/bin/bash

# =============================================================================
# Specify data:
# =============================================================================

main='/home/hannelore/Documents/ANALYSES/BTC_prepro'
input='/home/hannelore/Documents/ANALYSES/BTC_prepro/subjects/postop'

# PRE-OP #

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
#data_path[26]="${input}/PAT07T1"
#data_path[27]="${input}/PAT16T1"
#data_path[28]="${input}/PAT20T1"
#data_path[29]="${input}/PAT22T1"
#data_path[30]="${input}/PAT25T1"
#data_path[31]="${input}/PAT26T1"
#data_path[32]="${input}/PAT27T1"
#data_path[33]="${input}/PAT28T1"
#data_path[34]="${input}/PAT29T1"
#data_path[35]="${input}/PAT30T1"
#data_path[36]="${input}/PAT31T1"


# POST-OP #

data_path[0]="${input}/CON02T2"
data_path[1]="${input}/CON03T2"
data_path[2]="${input}/CON04T2"
data_path[3]="${input}/CON05T2"
data_path[4]="${input}/CON06T2"
data_path[5]="${input}/CON07T2"
data_path[6]="${input}/CON08T2"
data_path[7]="${input}/CON09T2"
data_path[8]="${input}/CON10T2"
data_path[9]="${input}/CON11T2"
#data_path[10]="${input}/PAT01T2"
data_path[11]="${input}/PAT02T2"
data_path[12]="${input}/PAT03T2"
data_path[13]="${input}/PAT05T2"
data_path[14]="${input}/PAT06T2"
data_path[15]="${input}/PAT07T2"
data_path[16]="${input}/PAT08T2"
data_path[17]="${input}/PAT10T2"
data_path[18]="${input}/PAT11T2" 
data_path[19]="${input}/PAT13T2"
data_path[20]="${input}/PAT15T2"
data_path[21]="${input}/PAT16T2"
data_path[22]="${input}/PAT17T2"
data_path[23]="${input}/PAT20T2"
data_path[24]="${input}/PAT23T2"
data_path[25]="${input}/PAT24T2"
#data_path[26]="${input}/PAT25T2"
#data_path[27]="${input}/PAT26T2"
#data_path[28]="${input}/PAT28T2"


# =============================================================================
# Part 1: Calculate RF per subject on dwi_distcor images
# =============================================================================
part1=0
if [ $part1 == 1 ]; then
	echo "Calculate individual RFs"

for subj_path in ${data_path[*]}
do
	subID=${subj_path: -7}

	echo ""
	echo ">>> Processing ${subID}"
	echo ""

	dwi_results="${subj_path}/dwi"

	dwi2response dhollander -mask ${dwi_results}/mask_biasfield.nii ${dwi_results}/dwi_distcor.nii -fslgrad ${dwi_results}/bvecs ${dwi_results}/bvals ${dwi_results}/wm_init.txt ${dwi_results}/gm_init.txt ${dwi_results}/csf_init.txt -quiet

done
else
	echo " "
fi

# =============================================================================
# Part 2: Calculate scaling factor from indidivual RFs 
# =============================================================================
part2=0
if [ $part2 == 1 ]; then
	echo "Run matlab script RF_scalingfactor.m"
else
	echo " "
fi


# =============================================================================
# Part 3: Normalise dwi_distcor by dividing by scaling factor & recalculate RFs
# =============================================================================
part3=0
if [ $part3 == 1 ]; then
	echo "Normalising dwi_distcor images by dividing by scaling factor"
	echo "and recalculate RFs"

for subj_path in ${data_path[*]}
do
	subID=${subj_path: -7}

	echo ""
	echo ">>> Processing ${subID}"
	echo ""

	dwi_results="${subj_path}/dwi"

	mrcalc ${dwi_results}/dwi_distcor.nii "$(cat ${dwi_results}/init_fact.txt)" -divide ${dwi_results}/dwi_initnorm.nii	-quiet

	dwi2response dhollander -mask ${dwi_results}/mask_biasfield.nii ${dwi_results}/dwi_initnorm.nii -fslgrad ${dwi_results}/bvecs ${dwi_results}/bvals ${dwi_results}/wm.txt ${dwi_results}/gm.txt ${dwi_results}/csf.txt -quiet
	
done

else
	echo " "
fi


# =============================================================================
# Part 4: Average RFs
# =============================================================================
part4=0
if [ $part4 == 1 ]; then
	echo "Average RFs"

	average_response $input/*/dwi/wm.txt $input/averageRF_wm.txt
	average_response $input/*/dwi/gm.txt $input/averageRF_gm.txt
	average_response $input/*/dwi/csf.txt $input/averageRF_csf.txt

else
	echo " "
fi

# Or use average RF from pre-operative assessment!

# =============================================================================
# Part 5: Run CSD & mtnormalise
# =============================================================================
part5=0
if [ $part5 == 1 ]; then
	echo "Run CSD & mtnormalise"

for subj_path in ${data_path[*]}
do
	subID=${subj_path: -7}

	echo ""
	echo ">>> Processing ${subID}"
	echo ""

	dwi_results="${subj_path}/dwi"
	
	dwi2fod msmt_csd -mask ${dwi_results}/mask_biasfield.nii ${dwi_results}/dwi_initnorm.nii -fslgrad ${dwi_results}/bvecs ${dwi_results}/bvals $main/subjects/averageRF_wm.txt ${dwi_results}/wm_fod_init.mif $main/subjects/averageRF_gm.txt ${dwi_results}/gm_fod_init.mif $main/subjects/averageRF_csf.txt ${dwi_results}/csf_fod_init.mif -quiet

	mtnormalise -mask ${dwi_results}/mask_biasfield.nii ${dwi_results}/wm_fod_init.mif ${dwi_results}/wm_fod.mif ${dwi_results}/gm_fod_init.mif ${dwi_results}/gm_fod.mif ${dwi_results}/csf_fod_init.mif ${dwi_results}/csf_fod.mif -quiet

	mrconvert -axes 0:2 -coord 3 0 ${dwi_results}/wm_fod.mif -quiet - | mrcat ${dwi_results}/csf_fod.mif ${dwi_results}/gm_fod.mif - ${dwi_results}/vf.mif -quiet

done 

else
	echo " "
fi

