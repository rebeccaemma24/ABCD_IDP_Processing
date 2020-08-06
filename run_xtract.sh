#!/bin/bash

# run xtract and NODDI once all other jobs are done

while read line; do
for subj in $line; do #nb in form 'sub-***' 

outdir=/share/neurodev/Rebecca/ABCD/derivatives/${subj}/ses-baselineYear1Arm1
diffdir=${outdir}/dwi_fsl
struct_list=/share/neurodev/Rebecca/adult_protocols/structureList
prot_list=/share/neurodev/Rebecca/adult_protocols

${FSLDIR}/bin/fsl_sub -q imgpascalq -l ${outdir}/xtract_logs -N xtract ${FSLDIR}/src/xtract/xtract -bpx ${outdir}/dwi_fsl.bedpostX -out ${outdir}/dwi_fsl.xtract -str ${struct_list} -p ${prot_list} -stdwarp ${outdir}/xfms/std2diff_warp.nii.gz ${outdir}/xfms/diff2std_warp.nii.gz -gpu



Pipeline_NODDI_Watson.sh ${diffdir} -Q imgpascalq

done
done < bedpostx_files.txt
