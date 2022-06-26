#! /bin/bash
# Purpose:     Code to download USBR hydromet data inventory
# Date:        May 2021
# Developer:   PK Shrestha
# Project:     mLM paper experiments
#
# Modifications:  1) xx xxxxx, DD month YYYY
# #########################################################

set -e

# User Control

   # Station types
   stntypes=( "Reservoir" "Stream" "Climate" )


#define output directory
work_dir="/Users/shresthp/Desktop/usbr_pn/"
# work_dir="/data/esm/global_mod/data/raw/usbr_hydromet/pn/"

# define directory with namelists files
main_dir="../../../data/lake/02_usbr_pn/"
# main_dir="../../../data/lake/02_usbr_pn/"

# read LUT:
list_fName=${main_dir}"hydromet_station_list_metadata.csv"

stnid=($(cat ${list_fName} | sed "1d" | cut -f 2 -d ","))
stntyp=($(cat ${list_fName} | sed "1d" | cut -f 3 -d ","))

echo "There are "${#stnid[@]}" entries in the LUT!"


# ================================================
# Prepare the station type folders, if not already
for j in "${!stntypes[@]}"; do
   if [ ! -d ${work_dir}${stntypes[j]} ]; then
      mkdir ${work_dir}${stntypes[j]}
   fi

   # Prepare DI folders, if not already
   if [ ! -d ${work_dir}${stntypes[j]}"/DI/" ]; then
      mkdir ${work_dir}${stntypes[j]}"/DI/"
   fi
done


# ================================================
# Loop through stations:
# for (( j = 0; j <  ${#stnid[@]}; j++ )) ; do 
for (( j = 0; j <  10; j++ )) ; do 

   echo ${stntyp[j]}", "${stnid[j]}

   # Generate weblink
   weblink="https://www.usbr.gov/pn-bin/inventory.pl?site="${stnid[j]}

   # Download with curl
   curl $weblink -o ${work_dir}${stntyp[j]}"/DI/"${stnid[j]}.html

   # Convert html to plain text
   pandoc -t plain ${work_dir}${stntyp[j]}"/DI/"${stnid[j]}.html -o ${work_dir}${stntyp[j]}"/DI/"${stnid[j]}.mdt

   # Delete the html file
   rm ${work_dir}${stntyp[j]}"/DI/"${stnid[j]}.html

done


exit 0


