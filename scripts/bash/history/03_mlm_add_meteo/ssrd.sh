#! /bin/bash
# Purpose:     Code BLOCK to fomrat ERA5 downward short wave radiation data
# Date:        Feb 2022
# Developer:   PK Shrestha
# Project:     mLM paper experiments
#
# Modifications:  1) xx xxxxx, DD month YYYY
# #########################################################

set -e


# clip and upscale to daily resolution
cdo -L daymean -sellonlatbox,@WWW@,@XXX@,@YYY@,@ZZZ@ ${datadir}surface_solar_radiation_downwards_@YRYRYR@.nc ${outdir_tmp}ssrd1.nc
# cdo -L daymean -sellonlatbox,@WWW@,@XXX@,@YYY@,@ZZZ@ ${datadir}surface_thermal_radiation_downwards_@YRYRYR@.nc ${outdir_tmp}strd1.nc

# convert J m-2 (daily cummulated) to W m-2 (rate)
cdo expr,ssrd=ssrd/86400.; ${outdir_tmp}ssrd1.nc ${outdir_tmp}ssrd2.nc

# Misc formatting
ncatted -O -a _FillValue,,d,, ${outdir_tmp}ssrd2.nc
ncatted -O -a _FillValue,,c,d,-9999. ${outdir_tmp}ssrd2.nc
ncatted -O -a missing_value,,m,d,-9999. ${outdir_tmp}ssrd2.nc

# make sure, the longitudes of nc files correspond to the ascii files:
## needs to be renamed in series...
ncrename -O -v longitude,lon -v latitude,lat ${outdir_tmp}ssrd2.nc ${outdir_tmp}ssrd3.nc
ncrename -O -d longitude,lon ${outdir_tmp}ssrd3.nc ${outdir_tmp}ssrd4.nc
ncrename -O -d latitude,lat ${outdir_tmp}ssrd4.nc ${outdir_tmp}ssrd5.nc

# Adjust longitude, if needed
ncap2 -s 'where(lon > 180.0) lon=lon-360.0; elsewhere lon=lon' -O ${outdir_tmp}ssrd5.nc ${outdir_tmp}ssrd6.nc

