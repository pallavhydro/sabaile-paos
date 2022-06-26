#! /bin/bash
# Purpose:     Code to download the downloaded USGS reservoirs/ stream site period of record
# Date:        June 2021
# Developer:   PK Shrestha
# Project:     mLM paper experiments
#
# Modifications:  1) xx xxxxx, DD month YYYY
# #########################################################

set -e

## User Control


# define output directory
work_dir="/Users/shresthp/Desktop/usgs/record_period/"
# work_dir="/data/esm/global_mod/data/raw/usbr_hydromet/usgs/Reservoir/record_period/"

# define directory with namelists files
main_dir="/Users/shresthp/Desktop/usgs/site_info/"
# main_dir="/data/esm/global_mod/data/raw/usbr_hydromet/usgs/Reservoir/record_period/"

# read LUT: combined site info file
cfile_siteinfo=${main_dir}"combined.rdb"

site_no=($(cat ${cfile_siteinfo} | sed "1,2d" | cut -f 2 -d$'\t')) # deletes 2 lines, then stores 2nd column i.e. USGS site number

echo "There are "${#site_no[@]}" entries in the LUT!"


# DOWNLOAD
# ================================================
# Loop through sites:

# for (( j = 0; j <  ${#site_no[@]}; j++ )) ; do 
for (( j = 0; j < 3; j++ )) ; do 

   echo ${site_no[j]}

   # Generate weblink
   weblink="https://waterservices.usgs.gov/nwis/site/?format=rdb&sites="${site_no[j]}"&seriesCatalogOutput=true"

   # Download with curl
   curl $weblink -o ${work_dir}${site_no[j]}".rdb"

done


exit 0





