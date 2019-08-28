#!/bin/bash

#PBS -N BTC_DWIpre
#PBS -m abe
#PBS -l walltime=72:00:00
#PBS -l nodes=1:ppn=18
#PBS -l vmem=30GB


# ==============================================================================
# FOLDER STRUCTURE:
#
#	> Main scripts: HPC_start_version.sh, DWI_prepro_version.sh and
#		input.txt
#
#	  !! Make sure to give right permissions (chmod +x scripts.sh)
#
#	> subjects > subID > RAWDATA
#					> T1 (DICOMs)
#					> DWI (DICOMs)
#					> DWI_PA (DICOMs)
#
#	> scripts
#				> DWI
#				> Templates
#
#	> files: b02b0.cnf and T1_2_MNI152_3mm.cnf FSL files
# ==============================================================================


# ==============================================================================
# DATA:
# ==============================================================================

if [ -z "$PBS_ARRAYID" ]
then
	echo 'ERROR: $PBS_ARRAYID is not set, submit job(s) using "qsub -t <array expression>"'
	exit 1
fi

# Directory where inputs are located: only required when copying from non-unix pc
#dos2unix $HOMEDIR/input.txt --quiet

# Make input variable with subIDs
export subID=`sed -n "${PBS_ARRAYID}p" $HOMEDIR/input.txt`
echo "subID: $subID"


# ==============================================================================
# SCRIPTS:
# ==============================================================================

DWI_scripts="$HOMEDIR/scripts/DWI"


echo "*************************************************************************"
echo "***               		 DWI ANALYSIS USING MRtrix3            				  ***"
echo "*************************************************************************"

echo "*** Convert DICOMs to NIfTI *********************************************"
${DWI_scripts}/dicom2nii_23082016.sh

echo "*** Distortion correction ***********************************************"
${DWI_scripts}/distcor_082017.sh

echo "*** Image registration **************************************************"
${DWI_scripts}/registration_112016.sh

echo "*** T1 data preprocessing ***********************************************"
${DWI_scripts}/anatomic_pre_112016.sh

echo "*** Intensity normalization & CSD (run locally) *************************"
${DWI_scripts}/intensitynorm_mtnorm.sh

echo "*** Whole-brain probabilistic tractography ******************************"
${DWI_scripts}/tractography_SS3T_5ttnorm.sh

echo "*** Create structural connectome (run locally) **************************"
${DWI_scripts}/SCnetwork_FS_082017.sh
