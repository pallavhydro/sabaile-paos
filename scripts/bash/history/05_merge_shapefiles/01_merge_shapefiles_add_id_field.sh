#!/bin/bash

# source directory with individual shpefiles
src="v2_basins_global_mhm_5722/"

# target directory to save the merged file to 
tar="v2_basins_global_mhm_5722_merged/"

# merging
for f in ${src}*.shp
do 
  # get filename/ ID
  base=$(basename -- "$f")
  base="${base%.*}"
  id="${base##*mask_}"

  echo $f $base $id

  # Create a character field named "ID"
  ogrinfo $f -sql "ALTER TABLE $base ADD COLUMN ID integer(10)"
  
  # Add the id to a field "ID"
  ogrinfo $f -dialect SQLite -sql "UPDATE $base SET ID = '$id'"
  
  # Append the shape file to the merged file
  ogr2ogr -update -append ${tar}basins_global_mhm_5722_merged.shp $f
done
