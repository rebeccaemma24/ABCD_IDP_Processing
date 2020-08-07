#!/bin/bash
#
# echo all structural IDPs into a single text file

subdir=$1
IDPdir=$2
subj=$3

l1=`cat ${subdir}/IDP_files/bb_IDP_T1_SIENAX.txt`
l2=`cat ${subdir}/IDP_files/bb_IDP_T1_FIRST_vols.txt`
l3=`cat ${subdir}/IDP_files/bb_IDP_T1_GM_parcellation.txt`

echo "${l1} ${l2} ${l3}" > ${IDPdir}/IDPs/${subj}/SIENAX_FIRST_GM_parcellation_IDPs.txt
