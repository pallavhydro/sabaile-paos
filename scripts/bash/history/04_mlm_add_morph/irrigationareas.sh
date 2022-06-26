#! /bin/bash
# Purpose:     Code BLOCK to fomrat GMIAv5 irrigation areas data
# Date:        May 2021
# Developer:   PK Shrestha
# Project:     mLM paper experiments
#
# Modifications:  1) xx xxxxx, DD month YYYY
# #########################################################

set -e


# GMIAv5 is in netCDF format at 1/12 degree/ 0.0833333 degree resolution. 

#####################################
## read in source data:
irrdir="/data/sawam/data/processed/data/global/global_irrigation_area/GMIAv5/"

#####################################

irrIN=${irrdir}gmia_v5_aei_pct.nc
irrasc=${outdir}irrigationareas.asc
irrf0=${outdir}irr0.nc
irrf1=${outdir}irr1.nc



##########################
## IRRIGATION AREAS:


# Convert to L0 resolution using NN and Clip
# CAN GDALWARP take nc in nc out? If not, this step has to be broken down to clip -> convert to tiff -> rescale
gdalwarp -s_srs ${epsg} -t_srs ${epsg} \
	     -tr 0.001953125 0.001953125 -r near -te ${xmin} ${ymin} ${xmax} ${ymax} \
	     -overwrite ${irrIN} \
	     ${irrf0}

# Rename the variable
cdo setname,percent_irrig_area ${irrf0} ${irrf1}

# Adjust the missing values and fill values to -9999
ncatted -O -a missing_value,percent_irrig_area,m,d,-9999. ${irrf1}
ncatted -O -a _FillValue,percent_irrig_area,m,d,-9999. ${irrf1}

# Convert to ASCII (unsigned I16 for smaller file size) for mhm input
gdal_translate -ot UInt16 -of AAIGrid ${irrf1} ${irrasc}