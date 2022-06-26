# ===========================================================
# ArcGIS python console script to
#
# "Generate dem (filled), fdir and facc from dem_v1 (unburnt) for Global extent"
#
# copy paste in the ArcGIS python console to run OR 
# 
# c:\python27\ArcGIS10.7\python.exe my_script.py
#
# Created by - Pallav Kumar Shrestha 
# date - June 2022
# ===========================================================


# Note: 
#       This script didn't work as fast as expected in python mode.
#	    The GUI was much faster, and thus used the model builder to do it.
#		Also, for now I will use only steps 1-5 + reclassify to convert NoData 
#       to -9999 + convert to ASCII. Will work with unmasked dem.


import arcpy
from arcpy import env
from arcpy.sa import *
import numpy as np


# checkout required extensions (required to be run as python script)
arcpy.CheckOutExtension("Spatial")

# enable overwriting
arcpy.env.overwriteOutput = True




domain_id = int("8020020760") # HYBAS_ID 8020020760, 2020057170, 5020037270


# directories
demdir    = "S:/arcgis/projects/01_global_hydrography/data/"
outdir    = "S:/arcgis/projects/01_global_hydrography/data/"

# construct the filepaths
ifile = demdir + "dem_shoreline_v1.tif"
cfile = demdir + "envelopes_with_buffer_for_hybas_lake_global_lev03_v1c.shp"





# 1 - select the required envelope

oshpfile = outdir + str(domain_id) + "/envelope_with_buffer.shp"
clause = " HYBAS_ID = " + str(domain_id)
arcpy.Select_analysis(cfile, oshpfile, where_clause=clause)

print("# 1 - select the required envelope [complete]")



# 2 - clip envelope extent from dem

otiffile = outdir + str(domain_id) + "/dem_clipped.tif"
demclip = arcpy.Clip_management(in_raster=ifile, in_template_dataset=oshpfile, nodata_value="-9999", clipping_geometry="ClippingGeometry", maintain_clipping_extent="NO_MAINTAIN_EXTENT")
demclip.save(otiffile) 

print("# 2 - clip envelope extent from dem [complete]")



# set snap raster and extent
arcpy.env.snapRaster = demclip
arcpy.env.extent = demclip



# 3 - fill the dem

otiffile = outdir + str(domain_id) + "/fill.tif"
demfill = Fill(demclip)
arcpy.SetRasterProperties_management(in_raster=demfill, nodata="1 -9999")
demfill.save(otiffile)

print("# 3 - fill the dem [complete]")



# 4 - fdir from filled dem

otiffile = outdir + str(domain_id) + "/fdir.tif"
demfdir = FlowDirection(demfill)
arcpy.SetRasterProperties_management(in_raster=demfdir, nodata="1 -9999")
demfdir.save(otiffile)

print("# 4 - fdir from filled dem [complete]")



# 5 - facc from fdir

otiffile = outdir + str(domain_id) + "/facc.tif"
demfacc = FlowAccumulation(demfdir,data_type="INTEGER")
arcpy.SetRasterProperties_management(in_raster=demfacc, nodata="1 -9999")
demfacc.save(otiffile)

print("# 5 - facc from fdir [complete]")



# 6 - basin raster from fdir

otiffile = outdir + str(domain_id) + "/basin.tif"
basin = Basin(demfdir)
arcpy.SetRasterProperties_management(in_raster=basin, nodata="1 -9999")
basin.save(otiffile)

print("# 6 - basin raster from fdir [complete]")



# 7 - basin shape from basin raster

oshpfile = outdir + str(domain_id) + "/basin.shp"
arcpy.RasterToPolygon_conversion(basin, oshpfile, simplify = "NO_SIMPLIFY", raster_field = "VALUE")

print("# 7 - basin shape from basin raster [complete]")




# 8 - Make taylor-made domain polygon mask

# (manually)


# 9 - select basin polygons intersecting with taylor-made domain polygon mask

ishpfile = outdir + str(domain_id) + "/taylor_make_domain_polygon.shp"
oshpfile = outdir + str(domain_id) + "/basin_selected.shp"
basinsel = arcpy.SelectLayerByLocation_management(in_layer=basinshp, oshpfile, overlap_type="INTERSECT", select_features=ishpfile)

print("# 9 - select basin polygons intersecting with taylor-made domain polygon mask [complete]")


# 10 - convert the selected basin polygons to raster (mask)

otiffile = outdir + str(domain_id) + "/mask.tif"
mask = arcpy.PolygonToRaster_conversion(basinsel, value_field="gridcode", cellsize=otiffile)
mask.save(otiffile)

print("# 10 - convert taylor-made domain polygon to a raster (mask) [complete]")


# 11 - mask out filled dem, fdir, facc with the raster mask. There are the 62-domains for global mlm exp

otiffile = outdir + str(domain_id) + "/fill_masked.tif"
oascfile = outdir + str(domain_id) + "/fill_masked.asc"
dem_masked = ExtractByMask(demfill, mask)
dem_masked.save(otiffile)
arcpy.RasterToASCII_conversion(in_raster=dem_masked, out_ascii_file=oascfile)

otiffile = outdir + str(domain_id) + "/fdir_masked.tif"
oascfile = outdir + str(domain_id) + "/fdir_masked.asc"
fdir_masked = ExtractByMask(demfdir, mask)
fdir_masked.save(otiffile)
arcpy.RasterToASCII_conversion(in_raster=fdir_masked, out_ascii_file=oascfile)

otiffile = outdir + str(domain_id) + "/facc_masked.tif"
oascfile = outdir + str(domain_id) + "/facc_masked.asc"
facc_masked = ExtractByMask(demfacc, mask)
facc_masked.save(otiffile)
arcpy.RasterToASCII_conversion(in_raster=facc_masked, out_ascii_file=oascfile)

print("# 11 - mask out filled dem, fdir, facc with the raster mask [complete]")



# # mosaic the filled dem, fdir and facc to global extent (in gdal?)
