library(rgrass7)
library(rdwplus)

# init grass
initGRASS(gisBase = "/Applications/GRASS-7.8.app/Contents/Resources",
          gisDbase = "/Users/shresthp/Nextcloud/Cloud/macbook/01_work/grassgis",
          location = "drainage",
          mapset = "PERMANENT",
          override=TRUE)


if(check_running()){
  # Load data set
  # dem <- system.file("extdata", "dem.tif", package = "rdwplus")
  dem <- "/Users/shresthp/Nextcloud/Cloud/macbook/01_work/Collab/01_mHM_Narayani_Manisha_Sah_NEC_IOE/mhm_input/01_input/morph/dem.tif"
  # stream_shp <- system.file("extdata", "streams.shp", package = "rdwplus")
  
  # Set environment parameters and import data to GRASS
  set_envir(dem)
  raster_to_mapset(rasters = c(dem), as_integer = c(FALSE))
  vector_to_mapset(vectors = c(stream_shp))
  
  # Create binary stream
  out_name <- paste0(tempdir(), "/streams_rast.tif")
  rasterise_stream("streams", out_name, overwrite = TRUE)
  reclassify_streams("streams_rast.tif", "streams_binary.tif", 
                     out_type = "binary", overwrite = TRUE)
  
  # Burn dem 
  burn_in(dem = "dem.tif", stream = "streams_binary.tif", out = "dem_burn.tif",
          burn = 10, overwrite = TRUE)
  
  # Fill sinks
  fill_sinks(dem = "dem_burn.tif", out = "dem_fill.tif", size = 1, overwrite = TRUE)
  
  # Derive flow accumulation and direction grids
  derive_flow(dem = "dem_fill.tif", 
              flow_dir = "fdir.tif", 
              flow_acc = "facc.tif", 
              overwrite = TRUE)
  
  # Plot
  plot_GRASS("fdir.tif", col = topo.colors(15))
  plot_GRASS("facc.tif", col = topo.colors(15))
}