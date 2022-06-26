#!/bin/bash

# ================
# WARNING! 
# ================
# Dont use this conversion script!!! 
# Conversion is done in 03_arcgis_terrain_analysis.py instead using
# ArcGIS tools of arcpy


# ===========================================================
# Bash script to convert raster tiffs to ASCII in mass

# Created by - Pallav Kumar Shrestha 
# date - July 2021
# ===========================================================


# datapath="/Users/shresthp/tmp/Win7/global_mlm/setup/morph_v1/adjusted"
datapath="/Users/shresthp/tmp/Win7/global_mlm/setup/morph_v1/adjusted_full_extent"

for basinid in ${datapath}/*; do

  echo ${basinid}

  for tiffile in ${basinid}"/morph/"*".tif"; do

    echo ${tiffile} 
    tiffilename=$(basename -- "$tiffile") # dem.tif, fdir.tif, ...
    tifname="${tiffilename%.*}"
    echo ${tifname} # dem, fdir, ...

    # construct input and output file names
    ifile=${tiffile}
    tfile1=${basinid}"/morph/"${tifname}"_temp1.nc"
    tfile2=${basinid}"/morph/"${tifname}"_temp2.nc"
    ofile=${basinid}"/morph/"${tifname}".asc"

    # deal with missing values
    gdal_translate ${ifile} ${tfile1}
    ncatted -O -a _FillValue,,d,, ${tfile1}
    ncatted -O -a _FillValue,,c,d,-9999. ${tfile1}
    ncatted -O -a missing_value,,m,d,-9999. ${tfile1}
    ncap2 -s "where('Band1' < -10000) 'Band1'=-9999.; elsewhere 'Band1'='Band1';" -O ${tfile1} ${tfile2}


    # convert tif to asc
    gdal_translate -of AAIgrid -ot Int32 ${tfile2} ${ofile}
      # Int32 - since all are intergers (dem, fdir, facc, idgauge, idlakeoutlets)

    # clean up
    rm ${tfile1} ${tfile2}

  done

done

