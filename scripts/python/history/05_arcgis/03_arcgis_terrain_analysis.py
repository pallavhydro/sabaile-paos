# ===========================================================
# ArcGIS python console script to
#
# "Generate dem (filled), fdir and facc from dem_v1 (unburnt)"
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

# checkout required extensions (required to be run as python script)
arcpy.CheckOutExtension("Spatial")

# enable overwriting
arcpy.env.overwriteOutput = True

# read the file with selected basinids
basinlist = np.genfromtxt("Z:/global_mlm/selection/atable_mlm_global_dam_selection_v1_tm.csv")

# directories
demdir    = "Z:/global_mlm/setup/morph_v1/extracted/"
# demdir    = "Z:/global_mlm/setup/morph_v1/extracted_full_extent/"
outdir    = "Z:/global_mlm/setup/morph_v1/adjusted/"
# outdir    = "Z:/global_mlm/setup/morph_v1/adjusted_full_extent/"
# maskdir   = "Z:/global_mlm/setup/masks_v1/tiff/"

# loop over the basin id list
for basinid in basinlist:
# for basinid in basinlist[80:81]:

  # we need integer
  basinid = int(basinid)

  print(basinid)

  # construct the input filepath
  ifile = demdir + str(basinid) + "/morph/dem.tif"
  # ifile = demdir + str(basinid) + "/morph/dem0.tif"


  # # 0 - define projection for the mask
  # mask     = maskdir + str(basinid) + ".tif"
  # arcpy.DefineProjection_management(
  #   in_dataset=mask, 
  #   coor_system="GEOGCS['GCS_WGS_1984',DATUM['D_WGS_1984',SPHEROID['WGS_1984',6378137.0,298.257223563]],PRIMEM['Greenwich',0.0],UNIT['Degree',0.0174532925199433]]"
  #   )


  # 1 - fill the unburnt dem
  otiffile = outdir + str(basinid) + "/morph/dem.tif"
  oascfile = outdir + str(basinid) + "/morph/dem.asc"
  demfill = Fill(ifile)
  arcpy.SetRasterProperties_management(in_raster=demfill, nodata="1 -9999")
  demfill.save(otiffile)
  arcpy.RasterToASCII_conversion(in_raster=demfill, out_ascii_file=oascfile)


  # ## MASKING - this section is not working for some of the cases, probably for the non-rectangular masks
  # # 2 - mask the filled dem 
  # otiffile = outdir + str(basinid) + "/morph/dem.tif"
  # oascfile = outdir + str(basinid) + "/morph/dem.asc"
  # demmask = Con(mask, demfill, "-9999", '"Value" = 0') # all masks have 0s and nodata
  # arcpy.SetRasterProperties_management(in_raster=demmask, nodata="1 -9999")
  # demmask.save(otiffile)
  # arcpy.RasterToASCII_conversion(in_raster=demmask, out_ascii_file=oascfile)



  # 3 - generate flow direction
  otiffile = outdir + str(basinid) + "/morph/fdir.tif"
  oascfile = outdir + str(basinid) + "/morph/fdir.asc"
  demfdir = FlowDirection(demfill)
  arcpy.SetRasterProperties_management(in_raster=demfdir, nodata="1 -9999")
  demfdir.save(otiffile)
  arcpy.RasterToASCII_conversion(in_raster=demfdir, out_ascii_file=oascfile)


  # 4 - generate flow accumulation
  otiffile = outdir + str(basinid) + "/morph/facc.tif"
  oascfile = outdir + str(basinid) + "/morph/facc.asc"
  demfacc = FlowAccumulation(demfdir,data_type="INTEGER")
  arcpy.SetRasterProperties_management(in_raster=demfacc, nodata="1 -9999")
  demfacc.save(otiffile)
  arcpy.RasterToASCII_conversion(in_raster=demfacc, out_ascii_file=oascfile)


