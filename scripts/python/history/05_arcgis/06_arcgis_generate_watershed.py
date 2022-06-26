# ===========================================================
# ArcGIS python console script to
#
# "Create watershed raster from idgauges and fdir"
#
# copy paste in the ArcGIS python console to run 
#
# Created by - Pallav Kumar Shrestha 
# date - Nov 2021
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


# Fdir folder
fdir_path = "Z:/global_mlm/setup/morph_v1/adjusted/"
# Snap pour point/ idgauges folder
snapPP_path = "Z:/global_mlm/setup/morph_v1/adjusted/"


# loop over the gauge id list
for i, gaugeid in enumerate(gaugelist):

  # we need integer
  gaugeid = int(gaugeid)

  print(gaugeid)


  # 1 - generate watershed from fdir and snapPP

  # construct paths
  fdir     = fdir_path    + str(gaugeid) + "/morph/fdir.tif"
  idgauges = snapPP_path  + str(gaugeid) + "/morph/idgauges.tif"
  otiffile = fdir_path    + str(gaugeid) + "/morph/watershed.tif"

  # snap
  watershed = Watershed( fdir, idgauges)

  # save the TIFF
  watershed.save(otiffile)














