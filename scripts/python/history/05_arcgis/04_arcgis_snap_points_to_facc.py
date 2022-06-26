# ===========================================================
# ArcGIS python console script to
#
# "Snap gauges and dams to facc"
#
# copy paste in the ArcGIS python console to run 
#
# Created by - Pallav Kumar Shrestha 
# date - July 2021
# ===========================================================

import arcpy
from arcpy import env
from arcpy.sa import *
import numpy as np
import pandas as pd

# checkout required extensions (required to be run as python script)
arcpy.CheckOutExtension("Spatial")

# enable overwriting
arcpy.env.overwriteOutput = True

# read the attribute table of selected dams shapefile as an array
table = pd.read_csv("Z:/global_mlm/selection/atable_mlm_global_dam_selection_v1_tm_adj_elv_gpsviz.csv").values # removes header

gaugelist = table[: , 76] # 77th column is global mhm gauge ID
damlist   = table[: , 2] # 3rd column is the GRanD ID

# Gauge shape file
ifile_gauges = "Z:/global_mlm/selection/global_mhm_5722_selection_v1_tm_adj.shp"
# Dam shape file
ifile_dams = "Z:/global_mlm/selection/mlm_global_dam_selection_v1_tm_adj.shp"
# Facc folder
data_path = "Z:/global_mlm/setup/morph_v1/adjusted_full_extent/"


# loop over the gauge id list
for i, gaugeid in enumerate(gaugelist):

  # we need integer
  gaugeid = int(gaugeid)

  print(gaugeid)


  # 1 - select gauge

  # construct where_clause
  clause = '"id" =' + str(gaugeid)

  # select gauge based on the ID field
  gauge_sel = arcpy.Select_analysis(in_features = ifile_gauges, where_clause = clause)



  # 2 - snap gauge to facc

  # construct paths
  facc     = data_path + str(gaugeid) + "/morph/facc.tif"
  otiffile = data_path + str(gaugeid) + "/morph/idgauges.tif"
  oascfile = data_path + str(gaugeid) + "/morph/idgauges.asc"

  # snap
  idgauges = SnapPourPoint( gauge_sel, facc, 0, "id" )

  # nodata to -9999 
  arcpy.SetRasterProperties_management(in_raster=idgauges, nodata="1 -9999")

  # save the TIFF and convert to ASCII
  idgauges.save(otiffile)
  arcpy.RasterToASCII_conversion(in_raster=idgauges, out_ascii_file=oascfile)




  # 3 - select dam

  # get dam id
  damid = damlist[i]

  # construct where_clause
  clause = '"GRAND_ID" =' + str(damid)

  # select dam based on the ID field
  dam_sel = arcpy.Select_analysis(in_features = ifile_dams, where_clause = clause)



  # 4 - snap dam to facc

  # construct paths
  otiffile = data_path + str(gaugeid) + "/morph/idlakeoutlets.tif"   # as the path is based on gauge id
  oascfile = data_path + str(gaugeid) + "/morph/idlakeoutlets.asc"

  # snap
  idlakeoutlets = SnapPourPoint( dam_sel, facc, 0, "GRAND_ID" )

  # nodata to -9999 
  arcpy.SetRasterProperties_management(in_raster=idlakeoutlets, nodata="1 -9999")

  # save the TIFF and convert to ASCII
  idlakeoutlets.save(otiffile)
  arcpy.RasterToASCII_conversion(in_raster=idlakeoutlets, out_ascii_file=oascfile)












