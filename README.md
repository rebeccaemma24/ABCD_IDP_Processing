# ABCD_IDP_Processing
Scripts to run processing on structural and diffusion imaging data for a large number of subjects including tract-specific microstructure IDPs. 

STEP 1: Run 'processData' 
- this sets up directory structure, runs the UKBB structural pipeline, DTIfit, DKI, and bedpostx, and creates warps between diffusion and standard MNI space. The diff2std warp is also applied so the success of warping can be checked visually 
- calls script 'directory_setup' to copy over and rename relevant files, and create nodif_brain and mask

STEP 2: Run 'run_xtract'
- this runs xtract and NODDI
- requires previous steps to be done, as warps and bedpostx files are required
- if running on a large number of subjects, it is advisable to comment out either the xtract or NODDI line using '#' to avoid submitting too many jobs at once and only run one of these at a time (i.e. NODDI submits ~20 jobs per subject, and xtract takes some time to run)

STEP 3: Run 'run_IDP_extraction'
- this extracts imaging-derived phenotypes for the structural and diffusion data, and provides a textfile in 'IDPdir/IDPs/sub-ID/sub-ID_IDPs.txt'
- NB ** this requires average tracts to already be created in standard space **
- runs UKBB structural IDP extraction and concatenates using 'struct_IDPs'
- prepares radial diffusivity maps and thresholds mean kurtosis maps
- warps all average tracts to each subject's diffusion-space and creates tract-specific IDP textfile using script 'micro_IDPs'
- concatenates all structural and diffusion IDPs into a textfile with headers using script 'concat_IDPs' 
- if any aspect of this is unsuccessful, the IDP string will be a different length to the string of headers 

Final output: sub-ID_IDPs.txt

Directory setup in each stript should be manually changed to match the user's directory structure, and textfiles being read to the input of subjects you are using. 
