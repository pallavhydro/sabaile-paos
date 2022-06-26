#! /bin/bash
# Purpose:     Code to combine data inventory of USBR reservoirs/ stream stations
# Date:        June 2021
# Developer:   PK Shrestha
# Project:     mLM paper experiments
#
# Modifications:  1) xx xxxxx, DD month YYYY
# #########################################################

set -e

## User Control


# define directory of data inventory files (also output directory)
work_dir="/Users/shresthp/Desktop/usbr_pn/"
# work_dir="/data/esm/global_mod/data/raw/usbr_hydromet/pn/"

# define directory with LUT
main_dir="../../../data/lake/02_usbr_pn/"
# main_dir="../../../data/lake/02_usbr_pn/"

# Station types
stntypes=( "Reservoir" "Stream" "Climate" "Snotel" )

# Parameter list
resparams=("af" "fb" "qd" "qev") # case sensitive, lower cases in the LUT
strparams=("qd" "gd" "qj")

# define the file name for the combined file
cfile="combined.csv"

# read LUT:
list_fName=${main_dir}"hydromet_station_list_metadata.csv"

stnid=($(cat ${list_fName} | sed "1d" | cut -f 2 -d ","))
stntyp=($(cat ${list_fName} | sed "1d" | cut -f 3 -d ","))

echo "There are "${#stnid[@]}" entries in the LUT!"


# INITIALIZE
# ================================================

# RESERVOIR
# create an empty file, starting point of the combined file
if [ -f ${work_dir}"Reservoir/DI/"${cfile} ]; then
   rm ${work_dir}"Reservoir/DI/"${cfile}
fi
touch ${work_dir}"Reservoir/DI/"${cfile}

header_line="CBTT"

# Loop through the full set of parameters and initialize the table header
for param in ${resparams[@]}; do
   # append the header line string
   header_line=${header_line}",syear_"${param}",eyear_"${param}
done

# print the header to the file
echo ${header_line} >> ${work_dir}"Reservoir/DI/"${cfile}


# STREAM
# create an empty file, starting point of the combined file
if [ -f ${work_dir}"Stream/DI/"${cfile} ]; then
   rm ${work_dir}"Stream/DI/"${cfile}
fi
touch ${work_dir}"Stream/DI/"${cfile}

header_line="CBTT"

# Loop through the full set of parameters and initialize the table header
for param in ${strparams[@]}; do
   # append the header line string
   header_line=${header_line}",syear_"${param}",eyear_"${param}
done

# print the header to the file
echo ${header_line} >> ${work_dir}"Stream/DI/"${cfile}




# COMBINE
# ================================================

# Loop through stations:
# for (( j = 0; j <  ${#stnid[@]}; j++ )) ; do 
for (( j = 0; j <  10; j++ )) ; do 

   echo ${stntyp[j]}", "${stnid[j]}

   # Initialize print line
   print_line=${stnid[j]}


   # Check the station type
   if [[ ${stntyp[j]} == ${stntypes[0]} ]]; then # Reservoir

      # Get the DI filepath
      ifile=${work_dir}${stntypes[0]}"/DI/"${stnid[j]}".mdt"

      # Loop through RESERVOIR variables
      for k in "${!resparams[@]}"; do 

         # Check if the parameter is persent in the data inventory file
         if grep -q ${resparams[k]} "${ifile}"; then

            syear_print=($(cat ${ifile} | sed -e "1,/${resparams[k]}/d" | head -4 | tail -1 | cut -b 1-4 )) 
                                       # extracts lines after 1st appearance of parameter code: sed
                                       # then stores only the top 4 lines: head
                                       # clips the last line only (which has the years): tail
                                       # then reads the first 4 characters to get starting year: cut

            eyear_print=($(cat ${ifile} | sed -e "1,/${resparams[k]}/d" | head -4 | tail -1 | rev | cut -b 1-4 | rev )) 
                                       # extracts lines after 1st appearance of parameter code
                                       # then stores only the top 4 lines
                                       # clips the last line only (which has the years)
                                       # then reads the last 4 characters to get ending year: rev, cut, rev
         else
            syear_print=-9999
            eyear_print=-9999
         fi

         # append the print line string
         print_line=${print_line}","${syear_print}","${eyear_print}

      done

      # print the data to the file
      echo ${print_line} >> ${work_dir}"Reservoir/DI/"${cfile}


   elif [[ ${stntyp[j]} == ${stntypes[1]} ]]; then # Stream


      # Get the DI filepath
      ifile=${work_dir}${stntypes[1]}"/DI/"${stnid[j]}".mdt"

      # Loop through STREAM variables
      for k in "${!strparams[@]}"; do 

         # Check if the parameter is persent in the data inventory file
         if grep -q ${strparams[k]} "${ifile}"; then

            syear_print=($(cat ${ifile} | sed -e "1,/${strparams[k]}/d" | head -4 | tail -1 | cut -b 1-4 )) 
                                       # extracts lines after 1st appearance of parameter code: sed
                                       # then stores only the top 4 lines: head
                                       # clips the last line only (which has the years): tail
                                       # then reads the first 4 characters to get starting year: cut

            eyear_print=($(cat ${ifile} | sed -e "1,/${strparams[k]}/d" | head -4 | tail -1 | rev | cut -b 1-4 | rev )) 
                                       # extracts lines after 1st appearance of parameter code
                                       # then stores only the top 4 lines
                                       # clips the last line only (which has the years)
                                       # then reads the last 4 characters to get ending year: rev, cut, rev
         else
            syear_print=-9999
            eyear_print=-9999
         fi

         # append the print line string
         print_line=${print_line}","${syear_print}","${eyear_print}

      done

      # print the data to the file
      echo ${print_line} >> ${work_dir}"Stream/DI/"${cfile}

   fi

done


exit 0





