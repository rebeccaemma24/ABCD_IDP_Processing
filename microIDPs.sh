#!/bin/bash
#
# microIDP extraction subscript to be called  

structure=$1
subj=$2
subdir=$3
IDPdir=$4
warpdir=$5
diffdir=$6
xtractdir=$7
outdir=$8


#----------------------------------
# 1: warp average tract masks into subj diffusion space
#---------------------------------- 

${FSLDIR}/bin/applywarp -i ${IDPdir}/xtract_averages/${structure}_av_mask.nii.gz -o ${subdir}/dwi_fsl.xtract/av_masks_native/${structure}_av_mask_native.nii.gz -w ${warpdir}/std2diff_warp.nii.gz -r ${diffdir}/nodif_brain_mask.nii.gz -d float

#----------------------------------
# 2: prepare for getting tract volume (binarise subj-specific tracts)
#---------------------------------- 

# make binary mask of tract in std space (thr=0.001)
${FSLDIR}/bin/fslmaths ${xtractdir}/${structure}/densityNorm.nii.gz -thr 0.001 -bin ${xtractdir}/${structure}/densityNorm_mask.nii.gz

# Warp this binarised mask into subj diff space
${FSLDIR}/bin/applywarp -i ${xtractdir}/${structure}/densityNorm_mask.nii.gz -o ${xtractdir}/${structure}/densityNorm_mask_native.nii.gz -w ${warpdir}/std2diff_warp.nii.gz -r ${diffdir}/nodif_brain_mask.nii.gz -d float

#----------------------------------
# 3: get microIDPs into a text file
#---------------------------------- 

avtractdir=${subdir}/dwi_fsl.xtract/av_masks_native

# volume of native mask
vol=(`fslstats ${subdir}/dwi_fsl.xtract/tracts/${structure}/densityNorm_mask_native.nii.gz -V`)

# microstructural features masked with average tract (in subject's diffusion space)

# DTI 
fa=`fslstats ${subdir}/dti/dti_FA.nii.gz -k ${avtractdir}/${structure}_av_mask_native.nii.gz -M`
md=`fslstats ${subdir}/dti/dti_MD.nii.gz -k ${avtractdir}/${structure}_av_mask_native.nii.gz -M`
ad=`fslstats ${subdir}/dti/dti_L1.nii.gz -k ${avtractdir}/${structure}_av_mask_native.nii.gz -M`
rd=`fslstats ${subdir}/dti/dti_RD.nii.gz -k ${avtractdir}/${structure}_av_mask_native.nii.gz -M`
mo=`fslstats ${subdir}/dti/dti_MO.nii.gz -k ${avtractdir}/${structure}_av_mask_native.nii.gz -M`

# DKI
kurt=`fslstats ${subdir}/dki/dki_kurt_thr.nii.gz -k ${avtractdir}/${structure}_av_mask_native.nii.gz -M`

# NODDI
fintra=`fslstats ${subdir}/dwi_fsl.NODDI_Watson/mean_fintra.nii.gz -k ${avtractdir}/${structure}_av_mask_native.nii.gz -M`
fiso=`fslstats ${subdir}/dwi_fsl.NODDI_Watson/mean_fiso.nii.gz -k ${avtractdir}/${structure}_av_mask_native.nii.gz -M`
OD=`fslstats ${subdir}/dwi_fsl.NODDI_Watson/OD.nii.gz -k ${avtractdir}/${structure}_av_mask_native.nii.gz -M`


# if text file already exists, delete and echo to new version of the file
if [ -e "${outdir}/${structure}_IDP.txt" ]; then

rm ${outdir}/${structure}_IDP.txt

fi

# echo to IDP file for that structure
touch ${outdir}/${structure}_IDP.txt
echo "${vol[1]} ${fa} ${md} ${ad} ${rd} ${mo} ${kurt} ${fintra} ${fiso} ${OD}" >> ${outdir}/${structure}_IDP.txt
