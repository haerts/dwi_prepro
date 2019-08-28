#!/bin/sh

#PBS -N BTC_DWIpre
#PBS -m abe
#PBS -l walltime=72:00:00
#PBS -l nodes=1:ppn=18
#PBS -l vmem=30GB

# >>> Instructions: type in HPC terminal:
# >>> qsub -t 1-n HPC_start_version.sh

# Swap cluster & load modules
module load MRtrix/3.0_RC2-foss-2017a-Python-2.7.13
module load FSL/5.0.9-centos6_64
. ${FSLDIR}/etc/fslconf/fsl.sh

# Set directories
export project="BTC_prepro"
export HOMEDIR=~/scratch_vo_user/$project
cd $HOMEDIR

# >>> Select analyses to run:
echo "Running DWI analyses"
./DWI_prepro_082017.sh ${PBS_ARRAYID}

echo "Jobs finished"
