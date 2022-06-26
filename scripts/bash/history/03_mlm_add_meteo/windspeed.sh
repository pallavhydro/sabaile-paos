#! /bin/bash
# Purpose:     Code BLOCK to fomrat ERA5 windspeed data
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
cdo -L daymean -sellonlatbox,@WWW@,@XXX@,@YYY@,@ZZZ@ ${datadir}10m_u_component_of_wind_@YRYRYR@.nc ${outdir_tmp}uwindspeed1.nc
cdo -L daymean -sellonlatbox,@WWW@,@XXX@,@YYY@,@ZZZ@ ${datadir}10m_v_component_of_wind_@YRYRYR@.nc ${outdir_tmp}vwindspeed1.nc

# merge the two wind components for calculating resultant windspeed
cdo merge ${outdir_tmp}uwindspeed1.nc ${outdir_tmp}vwindspeed1.nc ${outdir_tmp}uvwindspeed.nc

# calculate the resultant windspeed
cdo expr,windspeed='sqrt(sqr(u10)+sqr(v10))' ${outdir_tmp}uvwindspeed.nc ${outdir_tmp}windspeed1.nc

# remove the unwanted timebnds variable
ncks -C -x -v bnds,time_bnds ${outdir_tmp}windspeed1.nc ${outdir_tmp}windspeed2.nc

# Misc formatting
ncatted -O -a _FillValue,,d,, ${outdir_tmp}windspeed2.nc
ncatted -O -a _FillValue,,c,d,-9999. ${outdir_tmp}windspeed2.nc
ncatted -O -a missing_value,,m,d,-9999. ${outdir_tmp}windspeed2.nc

# make sure, the longitudes of nc files correspond to the ascii files:
## needs to be renamed in series...
ncrename -O -v longitude,lon -v latitude,lat ${outdir_tmp}windspeed2.nc ${outdir_tmp}windspeed3.nc
ncrename -O -d longitude,lon ${outdir_tmp}windspeed3.nc ${outdir_tmp}windspeed4.nc
ncrename -O -d latitude,lat ${outdir_tmp}windspeed4.nc ${outdir_tmp}windspeed5.nc

# Adjust longitude, if needed
ncap2 -s 'where(lon > 180.0) lon=lon-360.0; elsewhere lon=lon' -O ${outdir_tmp}windspeed5.nc ${outdir_tmp}windspeed6.nc
