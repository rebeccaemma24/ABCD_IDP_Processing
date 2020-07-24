#!/bin/bash

# A script to take in structural and diffusion data, and run the UKBioBank structural processing pipeline, DTIfit, DTIfit with --kurt, bedpostx, NODDI, and make std2diff and diff2std warps. XTRACT must be run seperately after this script is finished. 

# Needs input of: text file of all subject IDs in form sub-**** with only spaces between. Subjects must have both anat and dwi folders (if no T2w that is ok there is an if loop embedded)

#----------------------------------
# step 1: load in all subject IDs and set up paths
#---------------------------------- 
while read line; do
for subj in $line; do #nb in form 'sub-***' 

subdir=/share/neurodev/ABCD/data/${subj}/ses-baselineYear1Arm1
anat=${subdir}/anat
dwi=${subdir}/dwi
outdir=/share/neurodev/Rebecca/ABCD/derivatives/${subj}/ses-baselineYear1Arm1
diffdir=${outdir}/dwi_fsl

mkdir -p ${diffdir}

BB_BIN_DIR=/gpfs01/share/neurodev/Rebecca/ABCD/UK_biobank_pipeline_v_1
templ=${BB_BIN_DIR}/templates
export BB_BIN_DIR templ

#----------------------------------
# step 2: copy files for naming convention into dwi_fsl directory
#----------------------------------
jobID=`jobsub -q gpu -p 1 -g 1 -s "dir_setup" -c "sh directory_setup.sh ${dwi} ${subj} ${diffdir}" -t 01:00:00 -m 1`
echo ${jobID}
jobID=`echo -e $jobID | awk '{print $NF}'`

#----------------------------------
# step 3: run NODDI and bedpostx, dependent on prev one finishing
#----------------------------------
jobsub -q gpu -p 1 -g 1 -s "noddi_bedpost" -c "sh noddi_bedpost.sh ${diffdir}" -t 10:00:00 -m 1 -w ${jobID}

#----------------------------------
# step 4: run DTIfit (single shell data bvals 0 and 1000)
#----------------------------------
b1cmd=`${FSLDIR}/bin/fsl_sub -q long.q -j ${jobID} -l ${diffdir}/logs_b1 -N bvals_1000 ${FSLDIR}/bin/select_dwi_vols ${diffdir}/data.nii.gz ${diffdir}/bvals ${diffdir}/data_b1 0 -b 1000 -obv ${diffdir}/bvecs`

mkdir -p ${outdir}/dti

${FSLDIR}/bin/fsl_sub -q long.q -j ${b1cmd} -l ${outdir}/dti/logs -N dti ${FSLDIR}/bin/dtifit -k ${diffdir}/data_b1.nii.gz -o ${outdir}/dti/dti -m ${diffdir}/nodif_brain_mask -r ${diffdir}/data_b1.bvec -b ${diffdir}/data_b1.bval --save_tensor --sse 


#----------------------------------
# step 5: run DKIfit (only on bvals above 1000, multishell), getting mean kurtosis map
#----------------------------------
b2cmd=`${FSLDIR}/bin/fsl_sub -q long.q -j ${jobID} -l ${diffdir}/logs_b2 -N bvals_multi ${FSLDIR}/bin/select_dwi_vols ${diffdir}/data.nii.gz ${diffdir}/bvals ${diffdir}/data_b2 0 -b 1000 -b 2000 -b 3000 -obv ${diffdir}/bvecs`

mkdir -p ${outdir}/dki

${FSLDIR}/bin/fsl_sub -q long.q -j ${b2cmd} -l ${outdir}/dki/logs -N dki ${FSLDIR}/bin/dtifit -k ${diffdir}/data_b2.nii.gz -o ${outdir}/dki/dki -m ${diffdir}/nodif_brain_mask -r ${diffdir}/data_b2.bvec -b ${diffdir}/data_b2.bval --kurt --kurtdir --save_tensor --sse 

#----------------------------------
# step 6: get standard2diff and diff2standard warps (adult std space) 
#----------------------------------

# reorient T1 to standard space to help with registration
mkdir -p ${outdir}/T1
T1_reor=`${FSLDIR}/bin/fsl_sub -q long.q -j ${jobID} -l ${outdir}/T1/logs -N T1_reorient ${FSLDIR}/bin/fslreorient2std ${anat}/*_T1w.nii.gz ${outdir}/T1/T1`

# run UKBB structural pipeline (does non-linear FNIRT to get T1-> MNI transform with gradient distortion unwarping built in)
# include T2_FLAIR only if it is present, otherwise continue on with only T1
s_n=`echo "${subj:4}"`

if [ -e "${anat}/${subj}_ses-baselineYear1Arm1_run-01_T2w.nii.gz" ]; then

mkdir -p ${outdir}/T2_FLAIR
T2_reor=`${FSLDIR}/bin/fsl_sub -q long.q -j ${T1_reor} -l ${outdir}/T2_FLAIR/logs -N T2_reorient ${FSLDIR}/bin/fslreorient2std ${anat}/*_T2w.nii.gz ${outdir}/T2_FLAIR/T2_FLAIR`

ukbb=`${FSLDIR}/bin/fsl_sub -q long.q -j ${T2_reor} -l ${outdir}/T1/logs -N str_${s_n} ${BB_BIN_DIR}/bb_structural_pipeline/bb_struct_init_mb ${outdir}`

else

ukbb=`${FSLDIR}/bin/fsl_sub -q long.q -j ${T1_reor} -l ${outdir}/T1/logs -N str_${s_n} ${BB_BIN_DIR}/bb_structural_pipeline/bb_struct_init_mb ${outdir}`

fi

# run FLIRT to get diff->T1 (linear reg as the same brain different scan)
# uses: nodif_brain as input, T1_unbiased as reference, outputs a matrix file and nii.gz
# extra options: cost function bbr (so needs white matter segmentation mask), 256 bins (default), search angle -90 to 90 in x y z (default), 6 dofs, and spline interpolation
mkdir -p ${outdir}/xfms
flirtcmd=`${FSLDIR}/bin/fsl_sub -q long.q -j ${ukbb} -l ${outdir}/xfms/logs ${FSLDIR}/bin/flirt -in ${diffdir}/nodif_brain -ref ${outdir}/T1/T1_unbiased_brain.nii.gz -out ${outdir}/xfms/diff2str -omat ${outdir}/xfms/diff2str.mat -cost bbr -wmseg ${outdir}/T1/T1_fast/T1_brain_WM_mask.nii.gz -dof 6  -interp spline`

# now need to combine these into straight diff2std (diff->T1->MNI) 
convertcmd=`${FSLDIR}/bin/fsl_sub -q long.q -j ${flirtcmd} -l ${outdir}/xfms/logs ${FSLDIR}/bin/convertwarp --ref=${FSLDIR}/data/standard/MNI152_T1_1mm --premat=${outdir}/xfms/diff2str.mat --warp1=${outdir}/T1/transforms/T1_to_MNI_warp --out=${outdir}/xfms/diff2std_warp --rel`

# submit this double command using fslsub and apply the warp
${FSLDIR}/bin/fsl_sub -q long.q -j ${convertcmd} -l ${outdir}/xfms/logs ${FSLDIR}/bin/applywarp -i ${diffdir}/nodif_brain -r ${FSLDIR}/data/standard/MNI152_T1_1mm -w ${outdir}/xfms/diff2std_warp -o ${outdir}/xfms/diff2std --rel --interp=spline

# invert the warp to make std2diff 
${FSLDIR}/bin/fsl_sub -q long.q -j ${convertcmd} -l ${outdir}/xfms/logs ${FSLDIR}/bin/invwarp -w ${outdir}/xfms/diff2std_warp -o ${outdir}/xfms/std2diff_warp -r ${diffdir}/nodif_brain --rel

#----------------------------------
# step 7: remember to run xtract !!  
#----------------------------------

done
done < final_subs_1000.txt

