#! /bin/bash
# Purpose:     Code to download USBR hydromet data
# Date:        May 2021
# Developer:   PK Shrestha
# Project:     mLM paper experiments
#
# Modifications:  1) xx xxxxx, DD month YYYY
# #########################################################

set -e

# User Control
   
   # Time period
   syear=1950 
   eyear=2020

   # Parameter list
   resparams=("AF" "FB" "QD" "QEV")
   strparams=("QD" "GD" "QJ")

   # Station types
   stntypes=( "Reservoir" "Stream" "Climate" )

   # - Reservoir stations
   #    - AF      Reservoir Storage Content (acre-feet)
   #    - FB      Reservoir Forebay Elevation (feet) 
   #    - QD      Daily Mean Total Discharge (cfs)
   #    - QEV     Daily Mean Evaporation Rate (cfs)

   # - Stream stations
   #    - QD      Daily Mean Total Discharge (cfs)
   #    - GD      Daily Mean Gage Height (feet)
   #    - QJ      Daily Mean Canal Discharge (cfs)


#define output directory
work_dir="/Users/shresthp/Desktop/02_usbr_pn/"
# work_dir="/data/esm/global_mod/data/raw/usbr_pn_hydromet/"

# define directory with namelists files
main_dir="../../../data/reservoir_elevation/02_usbr_pn/"
# main_dir="/home/shresthp/projects/gitlab/global_mlm/data/reservoir_elevation/02_usbr_pn/"

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

   # Check the station type
   if [[ ${stntypes[j]} == ${stntypes[0]} ]]; then
      # Prepare the parameter folders for Reservoir
      for k in "${!resparams[@]}"; do
         if [ ! -d ${work_dir}${stntypes[j]}"/"${resparams[k]} ]; then
            mkdir ${work_dir}${stntypes[j]}"/"${resparams[k]}
         fi
      done
   elif [[ ${stntypes[j]} == ${stntypes[1]} ]]; then
      # Prepare the parameter folders for Stream 
      for k in "${!strparams[@]}"; do
         if [ ! -d ${work_dir}${stntypes[j]}"/"${strparams[k]} ]; then
            mkdir ${work_dir}${stntypes[j]}"/"${strparams[k]}
         fi
      done
   # add more conditional if Climate is to be included
   fi
done


# ================================================
# Loop through stations:
# for (( j = 0; j <  ${#stnid[@]}; j++ )) ; do 
for (( j = 0; j <  9; j++ )) ; do 

   echo ${stntyp[j]}", "${stnid[j]}

   # Check the station type
   if [[ ${stntyp[j]} == ${stntypes[0]} ]]; then # Reservoir


      # Loop through RESERVOIR variables
      for k in "${!resparams[@]}"; do 

         # Generate weblink
         weblink="https://www.usbr.gov/pn-bin/webarccsv.pl?parameter="${stnid[j]}"%20"${resparams[k]}"&syer=${syear}&smnth=1&sdy=1&eyer=${eyear}&emnth=12&edy=31&format=2"

         # Download with curl
         curl $weblink -o ${work_dir}${stntyp[j]}"/"${resparams[k]}"/"${stnid[j]}.day

      done
   
   elif [[ ${stntyp[j]} == ${stntypes[1]} ]]; then # Stream


      # Loop through STREAM variables
      for k in "${!strparams[@]}"; do 

         # Generate weblink
         weblink="https://www.usbr.gov/pn-bin/webarccsv.pl?parameter="${stnid[j]}"%20"${strparams[k]}"&syer=${syear}&smnth=1&sdy=1&eyer=${eyear}&emnth=12&edy=31&format=2"

         # Download with curl
         curl $weblink -o ${work_dir}${stntyp[j]}"/"${strparams[k]}"/"${stnid[j]}.day

      done

   fi
done


exit 0


