
# ===========================================================
# ArcGIS python console script
# copy paste in the ArcGIS python console to run 

# Created by - Pallav Kumar Shrestha 
# date - July 2021
# ===========================================================

import numpy as np

# read the file with selected basinids
basinlist = np.genfromtxt("Z:/global_mlm/selection/atable_mlm_global_dam_selection_v1_tm.csv")

# loop over the basin id list
for basinid in basinlist:

  print(basinid)

  # we need integer
  basinid = int(basinid)

  # construct where_clause
  clause = '"ID" =' + str(basinid)

  # select basin shape based on the ID field
  bsnshp = arcpy.Select_analysis(in_features="Z:/global_mlm/global_mhm/basins_global_mhm_5722_merged_dissolve_tm.shp", where_clause=clause)

  # select all grids that contain any part of the basin shape
  bsnshpsel = arcpy.SelectLayerByLocation_management(in_layer="Global_1degree_grid", overlap_type="INTERSECT", select_features = bsnshp, search_distance="", selection_type="NEW_SELECTION", invert_spatial_relationship="NOT_INVERT")

  # construct output file name
  ofile = "Z:/global_mlm/setup/masks_v1/shape/" + str(basinid) + ".shp"

  # save the selection grids as shapefile
  arcpy.CopyFeatures_management(in_features=bsnshpsel, out_feature_class=ofile)  