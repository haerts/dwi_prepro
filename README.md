# dwi_prepro
Scripts used for preprocessing of multi-shell HARDI DWI data of brain tumor patients and healthy control subjects in the following papers:
* Aerts H., Schirner M., Jeurissen B., Van Roost D., Achten E., Ritter P., & Marinazzo D. (2018). Modeling brain dynamics in brain tumor patients using The Virtual Brain. eNeuro 28 May 2018, 5 (3) ENEURO.0083-18.2018; https://doi.org/10.1523/ENEURO.0083-18.2018.
* Aerts H., Schirner M., Dhollander T., Jeurissen B., Achten E., Van Roost D., Ritter P., & Marinazzo D. (2019). Modeling brain dynamics after tumor resection using The Virtual Brain. biorXiv.
* Aerts H., Dhollander T., & Marinazzo D. (2019). Evaluating the performance of 3-tissue constrained spherical deconvolution pipelines for within-tumor tractography. biorXiv; https://doi.org/10.1101/629873.

The scripts use a combination of MRtrix3 (Tournier et al. 2019, biorXiv) and FSL (FMRIB’s Software Library; Jenkinson et al., 2012, NeuroImage; version 5.0.9) commands. The majority of scripts are created to run on HPC infrastructure, with the exception of 2 scripts that run locally (as indicated in the main script).

### Workflow

Main scripts: 
* HPC_start_082017.sh: script used to start pipeline on HPC infrastructure, calling DWI_prepro_082017.sh
* DWI_prepro_082017.sh: script detailing different preprocessing steps to be performed

(1) Convert data from DICOM to NIfTI
* dicom2nii_23082016.sh

(2) Distortion correction including denoising, corrections for gibbs ringing artefacts, motion and eddy currents, and bias field.
* distcor_082017.sh

(3) Registration between native T1w and DWI space
* registration_112016.sh

(4) Preprocessing of T1w data: segmentation
* anatomic_pre_112016.sh
* anatomic_pre_GLI: use "restored" T1w image after filling lesion mask with healthy tissue from contralateral side, obtained from the BCBToolkit (Foulon et al., 2018, GigaScience)

(5) Calculate group average response function, perform intensity normalization and obtain FODs using MSMT-CSD -- run locally
* intensitynorm_mtnorm.sh
* RF_scalingfactor.m (required for intensitynorm_mtnorm.sh)
* RF_scalingfactor_apply.m (required for intensitynorm_mtnorm.sh)

(6) Tractography: generate tracts using ACT framework (Smith et al., 2012, NeuroImage) and filter them using SIFT (Smith et al., 2013, NeuroImage)
* tractography_MSMT-CSD_30M.sh

(7) Construct structural connectivity network using FreeSurfer parcellation -- run locally
* SCnetwork_FS68_082017.sh
* SCnetwork_FS68_postop_112017.sh: including some adaptations to construct post-operative networks in brain tumor patients


