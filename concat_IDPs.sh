#!/bin/bash
#
# concatenate all IDP files into one long string for that subject. outdir is the directory where IDP text files are being stored for each subject. 

outdir=$1
subj=$2
ses=ses-baselineYear1Arm1

# all tract micro_IDPs into one file 

if [ -e "${outdir}/tract_micro_IDPs.txt" ]; then
rm ${outdir}/tract_micro_IDPs.txt 
fi

for structure in ac af_l af_r ar_l ar_r atr_l atr_r cbd_l cbd_r cbp_l cbp_r cbt_l cbt_r cst_l cst_r fa_l fa_r fma fmi fx_l fx_r ifo_l ifo_r ilf_l ilf_r mcp mdlf_l mdlf_r or_l or_r slf1_l slf1_r slf2_l slf2_r slf3_l slf3_r str_l str_r uf_l uf_r vof_l vof_r; do

echo -n "`cat ${outdir}/${structure}_IDP.txt` " >> ${outdir}/tract_micro_IDPs.txt

done

#echo "${s_ac} ${s_af_l} ${s_af_r} ${s_ar_l} ${s_ar_r} ${s_atr_l} ${s_atr_r} ${s_cbd_l} ${s_cbd_r} ${s_cbp_l} ${s_cbp_r} ${s_cbt_l} ${s_cbt_r} ${s_cst_l} ${s_cst_r} ${s_fa_l} ${s_fa_r} ${s_fma} ${s_fmi} ${s_fx_l} ${s_fx_r} ${s_ifo_l} ${s_ifo_r} ${s_ilf_l} ${s_ilf_r} ${s_mcp} ${s_mdlf_l} ${s_mdlf_r} ${s_or_l} ${s_or_r} ${s_slf1_l} ${s_slf1_r} ${s_slf2_l} ${s_slf2_r} ${s_slf3_l} ${s_slf3_r} ${s_str_l} ${s_str_r} ${s_uf_l} ${s_uf_r} ${s_vof_l} ${s_vof_r}" >> ${outdir}/tract_micro_IDPs.txt 


# combine structural and micro IDPs into one string

if [ -e "${outdir}/IDPs_list.txt" ]; then
rm ${outdir}/IDPs_list.txt 
fi

l1=`cat ${outdir}/SIENAX_FIRST_GM_parcellation_IDPs.txt`
l2=`cat ${outdir}/tract_micro_IDPs.txt`

echo -n "${subj} ${ses} ${l1} ${l2}" >> ${outdir}/IDPs_list.txt

# make string of headers
if [ -e "${outdir}/IDP_headers.txt" ]; then
rm ${outdir}/IDP_headers.txt 
fi

echo -n "subID sesID " >> ${outdir}/IDP_headers.txt

for i in `seq 1 1 11`; do
echo -n "SIENAX_${i} " >> ${outdir}/IDP_headers.txt
done

for j in `seq 1 1 15`; do
echo -n "FIRST_${j} " >> ${outdir}/IDP_headers.txt
done

for k in `seq 1 1 139`; do
echo -n "GM_${k} " >> ${outdir}/IDP_headers.txt
done

for structure in ac af_l af_r ar_l ar_r atr_l atr_r cbd_l cbd_r cbp_l cbp_r cbt_l cbt_r cst_l cst_r fa_l fa_r fma fmi fx_l fx_r ifo_l ifo_r ilf_l ilf_r mcp mdlf_l mdlf_r or_l or_r slf1_l slf1_r slf2_l slf2_r slf3_l slf3_r str_l str_r uf_l uf_r vof_l vof_r; do
	for n in `seq 1 1 10`;do
	echo -n "${structure}_${n} " >> ${outdir}/IDP_headers.txt
	done
done

# combine the headers and the values, then cleanup
if [ -e "${outdir}/${subj}_IDPs.txt" ]; then
rm ${outdir}/${subj}_IDPs.txt 
fi

hdr=`cat ${outdir}/IDP_headers.txt`
vals=`cat ${outdir}/IDPs_list.txt`

echo -e "${hdr}\n${vals}" >> ${outdir}/${subj}_IDPs.txt

rm ${outdir}/IDP_headers.txt
rm ${outdir}/IDPs_list.txt





