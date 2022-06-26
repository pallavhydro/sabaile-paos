#! /bin/bash
# Purpose:     Code to download daily data of USGS reservoirs/ stream sites
# Date:        June 2021
# Developer:   PK Shrestha
# Project:     mLM paper experiments
#
# Modifications:  1) xx xxxxx, DD month YYYY
# #########################################################

set -e

## User Control

# Reservoir or Stream?
site_type="Reservoir"

# define output directory
work_dir="/Users/shresthp/Desktop/usgs/daily_data/"
# work_dir="/data/esm/global_mod/data/raw/usbr_hydromet/usgs/${site_type}/daily_data/"

# define directory with LUT files
main_dir="/Users/shresthp/Desktop/usgs/record_period/"
# main_dir="/data/esm/global_mod/data/raw/usbr_hydromet/usgs/${site_type}/record_period/"




# DOWNLOAD
# ================================================
# Loop through sites:

for ifile in ${main_dir}*.rdb; do


   echo "$( basename ${ifile} )"

   if [[ ${site_type} == "Reservoir" ]]; then

      site_no=($(cat ${ifile} | sed -n '/dv/p' | cut -f 2 -d$'\t')) 
                                 # clips lines with dv data type code
                                 # then stores 2nd column i.e. USGS site number

      parm_cd=($(cat ${ifile} | sed -n '/dv/p' | cut -f 14 -d$'\t')) 
                                 # clips lines with dv data type code
                                 # then stores 14th column i.e. USGS parameter code

      stat_cd=($(cat ${ifile} | sed -n '/dv/p' | cut -f 15 -d$'\t')) 
                                 # clips lines with dv data type code
                                 # then stores 15th column i.e. USGS statistics code

   elif [[ ${site_type} == "Stream" ]]; then

      parm_cd="00060" # only streamflow

      site_no=($(cat ${ifile} | sed -n '/dv/p' | sed -n "/${parm_cd}/p" | cut -f 2 -d$'\t')) 
                                 # clips lines with dv data type code and 00060 (streamflow) parameter code
                                 # then stores 2nd column i.e. USGS site number

      stat_cd=($(cat ${ifile} | sed -n '/dv/p' | sed -n "/${parm_cd}/p" | cut -f 15 -d$'\t')) 
                                 # clips lines with dv data type code and 00060 (streamflow) parameter code
                                 # then stores 15th column i.e. USGS statistics code

   fi

   # Number of entries at this site
   nentries=${#site_no[@]}


   # Loop through entries:
   for (( j = 0; j < ${nentries}; j++ )) ; do 

      # Generate weblink
      if [[ ${site_type} == "Reservoir" ]]; then

         weblink="https://waterservices.usgs.gov/nwis/dv/?format=rdb&sites=${site_no[j]}&startDT=1950-01-01&endDT=2020-12-31&statCd=${stat_cd[j]}&parameterCd=${parm_cd[j]}&siteStatus=all"

         # Create parameter folder if not already
         if [ ! -d ${work_dir}${parm_cd[j]}"_"${stat_cd[j]} ]; then
            mkdir ${work_dir}${parm_cd[j]}"_"${stat_cd[j]}
         fi

         # Download with curl
         curl $weblink -o ${work_dir}${parm_cd[j]}"_"${stat_cd[j]}"/"${site_no[j]}".rdb"

      elif [[ ${site_type} == "Stream" ]]; then

         weblink="https://waterservices.usgs.gov/nwis/dv/?format=rdb&sites=${site_no[j]}&startDT=1950-01-01&endDT=2020-12-31&statCd=${stat_cd[j]}&parameterCd=${parm_cd}&siteStatus=all"

         # Create parameter folder if not already
         if [ ! -d ${work_dir}${parm_cd}"_"${stat_cd[j]} ]; then
            mkdir ${work_dir}${parm_cd}"_"${stat_cd[j]}
         fi

         # Download with curl
         curl $weblink -o ${work_dir}${parm_cd}"_"${stat_cd[j]}"/"${site_no[j]}".rdb"
      
      fi         

   done

done


exit 0





