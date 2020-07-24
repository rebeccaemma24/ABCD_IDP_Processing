#!/bin/bash

# run NODDI and bedpostx
diffdir=$1

Pipeline_NODDI_Watson.sh ${diffdir} 

bedpostx_gpu ${diffdir}
