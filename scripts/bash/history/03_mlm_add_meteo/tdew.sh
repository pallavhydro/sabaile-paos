#! /bin/bash
# Purpose:     Code BLOCK to fomrat ERA5 dew point temperature data
# Date:        May 2021
# Developer:   PK Shrestha
# Project:     mLM paper experiments
#
# Modifications:  1) xx xxxxx, DD month YYYY
# #########################################################

set -e

# Which is better?
# A. update homogenize_era5_template_annual.ncl for tdew and windspeed
# B. keep homogenize_era5_template_annual.ncl as is and put all additionals for tdew and windspeed here. 
# Note: we need tmax and tmin for mlm experiments (PET by Hargreaves Sammani)


# clip and upscale to daily resolution
cdo -L daymean -sellonlatbox,@WWW@,@XXX@,@YYY@,@ZZZ@ ${datadir}2m_dewpoint_temperature_@YRYRYR@.nc ${outdir_tmp}tdew1.nc

# convert K to Celsius
cdo expr,d2m=d2m-273.15; ${outdir_tmp}tdew1.nc ${outdir_tmp}tdew2.nc

# Misc formatting
ncatted -O -a _FillValue,,d,, ${outdir_tmp}tdew2.nc
ncatted -O -a _FillValue,,c,d,-9999. ${outdir_tmp}tdew2.nc
ncatted -O -a missing_value,,m,d,-9999. ${outdir_tmp}tdew2.nc

# make sure, the longitudes of nc files correspond to the ascii files:
## needs to be renamed in series...
ncrename -O -v longitude,lon -v latitude,lat ${outdir_tmp}tdew2.nc ${outdir_tmp}tdew3.nc
ncrename -O -d longitude,lon ${outdir_tmp}tdew3.nc ${outdir_tmp}tdew4.nc
ncrename -O -d latitude,lat ${outdir_tmp}tdew4.nc ${outdir_tmp}tdew5.nc

# Adjust longitude, if needed
ncap2 -s 'where(lon > 180.0) lon=lon-360.0; elsewhere lon=lon' -O ${outdir_tmp}tdew5.nc ${outdir_tmp}tdew6.nc

