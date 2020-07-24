#!/bin/bash

# set up directory structure and make nodif_brain and nodif_brain_mask 

dwi=$1
subj=$2
diffdir=$3

mkdir -p ${diffdir}

cp ${dwi}/${subj}_ses-baselineYear1Arm1_run-01_dwi.nii.gz ${diffdir}/data.nii.gz
cp ${dwi}/${subj}_ses-baselineYear1Arm1_run-01_dwi.bval ${diffdir}/bvals
cp ${dwi}/${subj}_ses-baselineYear1Arm1_run-01_dwi.bvec ${diffdir}/bvecs

# make nodif_brain and nodif_brainmask by selecting dwivol with approx bval of 0 (mean volume instead of concatenated) and then making brain-extracted mask
${FSLDIR}/bin/select_dwi_vols ${diffdir}/data.nii.gz ${diffdir}/bvals ${diffdir}/hifib0 0 -m
# using bet to make binary mask too (-m), fractional intensity threshold 0.25 less conservative, and use robust brain centre estimation which iterates BET several times
${FSLDIR}/bin/bet ${diffdir}/hifib0 ${diffdir}/nodif_brain -m -f 0.25 -R
