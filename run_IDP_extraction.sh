#!/bin/bash

# extract IDPs into text files necessary- this is one long textfile of numbers for each subj :) 

# Accompanying scripts: struct_IDPs.sh microIDPs.sh , concat_IDPs.sh

# *** AVERAGE TRACT MASKS MUST BE CREATED IN FORM ${structure}_av_mask.nii.gz AND STORED IN IDPdir/xtract_averages ***
# *** USE GET_AVERAGES.SH TO DO THIS STEP IF NOT ALREADY CREATED ***

#----------------------------------
# step 1: load in all subject IDs and set up paths
#---------------------------------- 
while read line; do
for subj in $line; do #nb in form 'sub-***' 

subdir=/share/neurodev/Rebecca/ABCD/derivatives/${subj}/ses-baselineYear1Arm1
T1=${subdir}/T1
T2=${subdir}/T2_FLAIR
diffdir=${subdir}/dwi_fsl
warpdir=${subdir}/xfms
IDPdir=/share/neurodev/Rebecca/ABCD/IDP_extraction
xtractdir=${subdir}/dwi_fsl.xtract/tracts

mkdir -p ${IDPdir}/IDPs/${subj}

#--------------------------------------
# step 2: STRUCTURAL IDPS
#--------------------------------------

cd /share/neurodev/Rebecca/ABCD/derivatives/${subj}
# Generate IDPs using ukbb pipeline script
BB_BIN_DIR=/share/neurodev/Rebecca/ABCD/UK_biobank_pipeline_v_1
templ=${BB_BIN_DIR}/templates
export BB_BIN_DIR templ

bb_IDP=`${FSLDIR}/bin/fsl_sub -q short.q -l ${T1}/logs -N idp_${subj} ${BB_BIN_DIR}/bb_IDP/bb_IDP ${subdir}` 

# Put all subjects IDPs in a single file, by calling struct_IDPs
${FSLDIR}/bin/fsl_sub -q short.q -l ${IDPdir}/IDPs/${subj}/logs -j ${bb_IDP} -N struct_IDPs sh struct_IDPs.sh ${subdir} ${IDPdir} ${subj}

echo `date` submitted structural IDPs

#--------------------------------------
# step 3: MICROSTRUCTURAL TRACT-SPECIFIC IDPS
#--------------------------------------

#----------------------------------
# 3i: prepare dti/dki
#---------------------------------- 

# get radial diffusivity map (L2+L3)/2
rd=`${FSLDIR}/bin/fsl_sub -q short.q -l ${subdir}/dti/logs ${FSLDIR}/bin/fslmaths ${subdir}/dti/dti_L2.nii.gz -add ${subdir}/dti/dti_L3.nii.gz -div 2 ${subdir}/dti/dti_RD.nii.gz`

# threshold dki_kurt data to be between 0 and 5
dki_thr=`${FSLDIR}/bin/fsl_sub -q short.q -l ${subdir}/dki/logs -j ${rd} ${FSLDIR}/bin/fslmaths ${subdir}/dki/dki_kurt.nii.gz -thr 0 -uthr 5 ${subdir}/dki/dki_kurt_thr.nii.gz`

#----------------------------------
# 3ii: warp average tract masks into subj diffusion space
#---------------------------------- 
mkdir -p ${subdir}/dwi_fsl.xtract/av_masks_native

for structure in ac af_l af_r ar_l ar_r atr_l atr_r cbd_l cbd_r cbp_l cbp_r cbt_l cbt_r cst_l cst_r fa_l fa_r fma fmi fx_l fx_r ifo_l ifo_r ilf_l ilf_r mcp mdlf_l mdlf_r or_l or_r slf1_l slf1_r slf2_l slf2_r slf3_l slf3_r str_l str_r uf_l uf_r vof_l vof_r; do

tract_stats=`${FSLDIR}/bin/fsl_sub -q short.q -j ${dki_thr} -l ${IDPdir}/IDPs/${subj}/logs -N tract_stats sh microIDPs.sh ${structure} ${subj} ${subdir} ${IDPdir} ${warpdir} ${diffdir} ${xtractdir} ${IDPdir}/IDPs/${subj}`

done

echo `date` ALL MICRO IDPS EXTRACTED 

#----------------------------------
# step 4: COMBINE ALL IDPS TOGETHER
#---------------------------------- 

# call concat_IDPs, which creates a text file of all micro IDPs, and creates one text file of all structural and micro IDPs for each subject in their folder 
# needs: IDP_files directory (the outdir), subj
${FSLDIR}/bin/fsl_sub -q short.q -l ${IDPdir}/IDPs/${subj}/logs -j ${tract_stats} -N concat_IDPs sh concat_IDPs.sh ${IDPdir}/IDPs/${subj} ${subj}


done
done < subj_IDs.txt
