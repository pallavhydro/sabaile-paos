#! /bin/bash
# Purpose:     Code to download USGS reservoirs/ stream station list
# Date:        June 2021
# Developer:   PK Shrestha
# Project:     mLM paper experiments
#
# Modifications:  1) xx xxxxx, DD month YYYY
# #########################################################

set -e

## User Control


# define output directory
work_dir="/Users/shresthp/Desktop/usgs/site_info/"
# work_dir="/data/esm/global_mod/data/raw/usgs/lake/site_info/"

# define directory with namelists files
main_dir="../../../data/lake/03_usgs/"
# main_dir="/home/shresthp/projects/gitlab/global_mlm/data/lake/03_usgs/"

# read LUT: ANSI codes for states of USA
list_statesName=${main_dir}"ansi_codes_states_of_usa.txt"

state_ansi=($(cat ${list_statesName} | sed "1d" | cut -f 2 -d "|")) # stores 2nd column i.e. ANSI states codes

echo "There are "${#state_ansi[@]}" entries in the LUT!"


# DOWNLOAD
# ================================================
# Loop through states:

# for (( j = 0; j <  ${#state_ansi[@]}; j++ )) ; do 
for (( j = 0; j < 3; j++ )) ; do 

   echo ${state_ansi[j]}

   # Generate weblink
   weblink="https://waterservices.usgs.gov/nwis/site/?format=rdb&stateCd="${state_ansi[j]}"&siteOutput=expanded&parameterCd=00054,00062,62614,62615,62616,62617,62618,72021,72022,72023,72036&siteType=LK&siteStatus=all&hasDataTypeCd=dv"
            # siteType can be LK (lake) or ST (stream)
            # for LK, parameterCd=00054,00062,62614,62615,62616,62617,62618,72021,72022,72023,72036
            # for ST, parameterCd=00060

   # Download with curl
   curl $weblink -o ${work_dir}${state_ansi[j]}".rdb"

done


exit 0


