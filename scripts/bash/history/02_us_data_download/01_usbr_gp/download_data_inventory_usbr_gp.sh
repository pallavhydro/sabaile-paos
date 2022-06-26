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
   stntypes=( "Reservoir" "Stream" "Climate" "Snotel" )


#define output directory
work_dir="/Users/shresthp/Desktop/usbr_gp/"
# work_dir="/data/esm/global_mod/data/raw/usbr_hydromet/"

# define directory with namelists files
main_dir="../../../data/lake/01_usbr_gp/"
# main_dir="/home/shresthp/projects/global_mlm/data/reservoir_elevation/01_usbr/"

# read LUT:
list_fName=${main_dir}"location_hydromet_joined_usbr.csv"

stnid=($(cat ${list_fName} | sed "1d" | cut -f 2 -d ","))
stntyp=($(cat ${list_fName} | sed "1d" | cut -f 10 -d ","))

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
for (( j = 0; j <  9; j++ )) ; do 

   echo ${stntyp[j]}", "${stnid[j]}

   # Generate weblink
   weblink="https://www.usbr.gov/gp-bin/inventory.pl?site="${stnid[j]}

   # Download with curl
   curl $weblink -o ${work_dir}${stntyp[j]}"/DI/"${stnid[j]}.mdt

done


exit 0


