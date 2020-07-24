#!/bin/bash

# run xtract once all other jobs are done

while read line; do
for subj in $line; do #nb in form 'sub-***' 

outdir=/share/neurodev/Rebecca/ABCD/derivatives/${subj}/ses-baselineYear1Arm1
struct_list=/share/neurodev/Rebecca/adult_protocols/structureList
prot_list=/share/neurodev/Rebecca/adult_protocols

cmd="xtract -bpx ${outdir}/dwi_fsl.bedpostX -out ${outdir}/dwi_fsl.xtract -str ${struct_list} -p ${prot_list} -stdwarp ${outdir}/xfms/std2diff_warp.nii.gz ${outdir}/xfms/diff2std_warp.nii.gz -gpu"
jobsub -q gpu -p 1 -g 1 -s "xtract" -c "${cmd}" -t 10:00:00 -m 1


done
done < final_subs_1000.txt
