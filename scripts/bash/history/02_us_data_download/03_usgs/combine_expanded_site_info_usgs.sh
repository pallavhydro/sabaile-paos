#! /bin/bash
# Purpose:     Code to combine the downloaded USGS reservoirs/ stream station list
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
# work_dir="/data/esm/global_mod/data/raw/usbr_hydromet/usgs/Reservoir/site_info/"

# define the file name for the combined file
cfile="combined.rdb"




# COMBINE
# ================================================

# create an empty file, starting point of the combined file
if [ -f ${work_dir}${cfile} ]; then
   rm ${work_dir}${cfile}
fi
touch ${work_dir}${cfile}



# Loop through individual states station list:

for ifile in ${work_dir}??.rdb; do

   echo "$( basename ${ifile} )"

   # check whether there are entries in the file
   nlines_file=$( wc -l < ${ifile} )

   if (( ${nlines_file} == 0 )); then
      # no entries
      echo "$( basename ${ifile} )"" has no entries!"
   else
      # check whether the cfile has been initialized
      nlines_cfile=$( wc -l < ${work_dir}${cfile} )

      if (( ${nlines_cfile} == 0 )); then
         # append including the header
         sed -n '60,$p' ${ifile} >> ${work_dir}${cfile}
      else      
         # append only the entries
         sed -n '62,$p' ${ifile} >> ${work_dir}${cfile}
      fi
   fi

done


exit 0


