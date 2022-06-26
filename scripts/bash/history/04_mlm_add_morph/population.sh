#! /bin/bash
# Purpose:     Code BLOCK to fomrat GPWv4 population data
# Date:        May 2021
# Developer:   PK Shrestha
# Project:     mLM paper experiments
#
# Modifications:  1) xx xxxxx, DD month YYYY
# #########################################################

set -e


# GPWv4 is in netCDF format at 1/24 degree/ 0.04166666 degree resolution. 

#####################################
## read in source data:
popdir="/data/sawam/data/processed/data/global/global_population/GPWv4/"

#####################################

popIN=${popdir}gpw_v4_population_density_rev11_2pt5_min_2000.nc
popasc=${outdir}population.asc
popf0=${outdir}pop0.nc
popf1=${outdir}pop1.nc



##########################
## POPULATION:


# Convert to L0 resolution using NN and Clip
# CAN GDALWARP take nc in nc out? If not, this step has to be broken down to clip -> convert to tiff -> rescale
gdalwarp -s_srs ${epsg} -t_srs ${epsg} \
	     -tr 0.001953125 0.001953125 -r near -te ${xmin} ${ymin} ${xmax} ${ymax} \
	     -overwrite ${popIN} \
	     ${popf0}

# Rename the variable
cdo setname,population_density ${popf0} ${popf1}

# Adjust the missing values and fill values to -9999
ncatted -O -a missing_value,population_density,m,d,-9999. ${popf1}
ncatted -O -a _FillValue,population_density,m,d,-9999. ${popf1}

# Convert to ASCII (unsigned I16 for smaller file size) for mhm input
gdal_translate -ot UInt16 -of AAIGrid ${popf1} ${popasc}