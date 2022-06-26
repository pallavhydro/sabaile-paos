#! /bin/bash
# Purpose:     Code to combine period of record of USGS reservoirs/ stream sites
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
work_dir="/Users/shresthp/Desktop/usgs/record_period/"
# work_dir="/data/esm/global_mod/data/raw/usbr_hydromet/usgs/${site_type}/record_period/"

# define directory with period of record files
main_dir="/Users/shresthp/Desktop/usgs/record_period/"
# main_dir="/data/esm/global_mod/data/raw/usbr_hydromet/usgs/${site_type}/record_period/"

# define directory with daily data/ full set of parameter_statistics folders
parmstat_dir="/Users/shresthp/Desktop/usgs/daily_data/"
# parmstat_dir="/data/esm/global_mod/data/raw/usbr_hydromet/usgs/${site_type}/daily_data/"

# define the file name for the combined file
cfile="combined.csv"


# INITIALIZE
# ================================================

# create an empty file, starting point of the combined file
if [ -f ${work_dir}${cfile} ]; then
   rm ${work_dir}${cfile}
fi
touch ${work_dir}${cfile}

header_line="site_no"

# Loop through the full set of parameter_statistics and initialize the table header
for iparmstat in ${parmstat_dir}*; do
   parmstat_name=$( basename ${iparmstat} )
   # append the header line string
   header_line=${header_line}",syear_"${parmstat_name}",eyear_"${parmstat_name}",ndata_"${parmstat_name}
done

# print the header to the file
echo ${header_line} >> ${work_dir}${cfile}



# COMBINE
# ================================================
# Loop through sites period of record:

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

      syear=($(cat ${ifile} | sed -n '/dv/p' | cut -f 22 -d$'\t' | cut -f 1 -d '-')) 
                                 # clips lines with dv data type code
                                 # then extracts the 22nd column i.e. begin_date
                                 # then stores the year

      eyear=($(cat ${ifile} | sed -n '/dv/p' | cut -f 23 -d$'\t' | cut -f 1 -d '-')) 
                                 # clips lines with dv data type code
                                 # then extracts the 23rd column i.e. end_date
                                 # then stores the year

      ndata=($(cat ${ifile} | sed -n '/dv/p' | cut -f 24 -d$'\t')) 
                                 # clips lines with dv data type code
                                 # then stores 24th column i.e. record count

   elif [[ ${site_type} == "Stream" ]]; then

      parm_cd="00060" # only streamflow

      site_no=($(cat ${ifile} | sed -n '/dv/p' | sed -n "/${parm_cd}/p" | cut -f 2 -d$'\t')) 
                                 # clips lines with dv data type code and 00060 (streamflow) parameter code
                                 # then stores 2nd column i.e. USGS site number

      stat_cd=($(cat ${ifile} | sed -n '/dv/p' | sed -n "/${parm_cd}/p" | cut -f 15 -d$'\t')) 
                                 # clips lines with dv data type code and 00060 (streamflow) parameter code
                                 # then stores 15th column i.e. USGS statistics code

      syear=($(cat ${ifile} | sed -n '/dv/p' | sed -n "/${parm_cd}/p" | cut -f 22 -d$'\t' | cut -f 1 -d '-')) 
                                 # clips lines with dv data type code
                                 # then extracts the 22nd column i.e. begin_date
                                 # then stores the year

      eyear=($(cat ${ifile} | sed -n '/dv/p' | sed -n "/${parm_cd}/p" | cut -f 23 -d$'\t' | cut -f 1 -d '-')) 
                                 # clips lines with dv data type code
                                 # then extracts the 23rd column i.e. end_date
                                 # then stores the year

      ndata=($(cat ${ifile} | sed -n '/dv/p' | sed -n "/${parm_cd}/p" | cut -f 24 -d$'\t')) 
                                 # clips lines with dv data type code
                                 # then stores 24th column i.e. record count

   fi

   # Number of entries (parameters) at this site
   nentries=${#site_no[@]}

   # Initialize print line
   print_line=${site_no[0]}   # all values of site_no vector would be same

   # Loop through the full set of parameter_statistics
   for iparmstat in ${parmstat_dir}*; do

      parmstat_name=$( basename ${iparmstat} )
      syear_print=-9999
      eyear_print=-9999
      ndata_print=-9999

      # Loop through entries:
      for (( j = 0; j < ${nentries}; j++ )) ; do 
         if [[ ${site_type} == "Reservoir" ]]; then
            if [[ ${parmstat_name} == ${parm_cd[j]}"_"${stat_cd[j]} ]]; then
               syear_print=${syear[j]}
               eyear_print=${eyear[j]}
               ndata_print=${ndata[j]}
               break
            fi
         elif [[ ${site_type} == "Stream" ]]; then
            if [[ ${parmstat_name} == ${parm_cd}"_"${stat_cd[j]} ]]; then
               syear_print=${syear[j]}
               eyear_print=${eyear[j]}
               ndata_print=${ndata[j]}
               break
            fi
         fi
      done

      # append the print line string
      print_line=${print_line}","${syear_print}","${eyear_print}","${ndata_print}

   done

   # print the data to file
   echo ${print_line} >> ${work_dir}${cfile}

done


exit 0





