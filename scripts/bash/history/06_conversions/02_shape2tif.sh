#!/bin/bash

# ===========================================================
# Bash script to convert shapefile to raster tiffs in mass

# Created by - Pallav Kumar Shrestha 
# date - July 2021
# ===========================================================


inpath="/Users/shresthp/tmp/Win7/global_mlm/setup/masks_v1/shape/"
outpath="/Users/shresthp/tmp/Win7/global_mlm/setup/masks_v1/tiff/"


for basinshape in ${inpath}*.shp; do


  echo ${basinshape}
  basinshapefilename=$(basename -- "$basinshape")
  basinid="${basinshapefilename%.*}"
  echo ${basinid}

  # construct output file name
  ofile=${outpath}${basinid}".tif"

  # convert shp to tif
  gdal_rasterize -a "Id" -ot Int16 -a_nodata -9999 -tap -tr 0.001953125 0.001953125 ${basinshape} ${ofile}


done


