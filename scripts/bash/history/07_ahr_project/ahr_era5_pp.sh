#! /bin/bash
# date 4 March 2022
# Pallav Shrestha
# Preprocess ERA5 temperature for Ahr project:
# #########################################################
set -e
source load_netcdf_0_3.sh


# Clip minimum rectangular extent that covers Ahr extent from ERA5 global extent 
cdo sellonlatbox,6.375,7.375,49.875,50.875 /data/esm/global_mod/data/processed/era5/2m_temperature_2006.nc t2m_ahr_1.nc

# Convert form K to deg C
cdo -b 32 subc,273.15 t2m_ahr_1.nc t2m_ahr_2.nc

# Misc formatting
ncatted -O -a _FillValue,,d,, t2m_ahr_2.nc
ncatted -O -a _FillValue,,c,d,-9999. t2m_ahr_2.nc
ncatted -O -a missing_value,,m,d,-9999. t2m_ahr_2.nc
ncatted -O -a units,t2m,d,, t2m_ahr_2.nc
ncatted -O -a units,t2m,c,c,degC t2m_ahr_2.nc


# latlon should be "lat" and "lon"
ncrename -O -v longitude,lon -v latitude,lat t2m_ahr_2.nc t2m_ahr_3.nc
ncrename -O -d longitude,lon t2m_ahr_3.nc t2m_ahr_4.nc
ncrename -O -d latitude,lat t2m_ahr_4.nc t2m_ahr_5.nc


# Adjust longitude, if needed
ncap2 -s 'where(lon > 180.0) lon=lon-360.0; elsewhere lon=lon' -O t2m_ahr_5.nc t2m_ahr_6.nc


# Remap t2m data from native ERA5 resolution (0.25 deg) to Ahr project resolution (0.015625 deg)
# This also clips the extent to the exact extent of Ahr data (e.g. pre.nc)
cdo griddes pre.nc > grid.txt
cdo -P 8 remapnn,grid.txt t2m_ahr_6.nc t2m_ahr_7.nc 


# Generate dummy hourly tmax and tmin data with +/- 5 degree from t2m
cdo subc,5 t2m_ahr_7.nc t2m_ahr_8.nc
cdo addc,5 t2m_ahr_7.nc t2m_ahr_9.nc


# Finalize files
cdo -f nc4c -z zip_4 copy t2m_ahr_7.nc tavg.nc
cdo -f nc4c -z zip_4 copy t2m_ahr_8.nc tmin.nc
cdo -f nc4c -z zip_4 copy t2m_ahr_9.nc tmax.nc