## ----------------------------------------------------------------------------
## Name         mapplot_restartfile.R (in R)
## Written      Pallav Kumar Shrestha, 2022/06/16
## Copyright    CC BY 4.0
## Purpose      Creates map/s of selected variable from mhm or mrm restart file. 
##              Output file is restart_map_<var>.pdf. The file colormaps.R
##              must be placed together with this script.
## References
## ----------------------------------------------------------------------------


# (1.1) LIBRARIES PREPARATION ===================

# Check for the required packages
list.of.packages <- c("ggplot2", "ncdf4", "graphics", "RColorBrewer", "chron", "plyr", 
                      "lattice", "gridExtra", "grid", "classInt", "tools")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages, repos = "http://cran.us.r-project.org")

# Open libraries/ packages
# silence on
oldw <- getOption("warn")
options(warn = -1) 

library(ggplot2)
library(ncdf4) 
library(graphics) 
library(RColorBrewer)
library(chron)
library(plyr)
library(lattice)
library(gridExtra)  # for using "grid.arrange" function
library(grid)
library(classInt)
library(tools)

options(warn = oldw) 
# silence off   



# (1.2) CONTROLS ===================


# set working directory to the path of this script
setwd(dirname(rstudioapi::getSourceEditorContext()$path))
# load modules
source("colormaps.R")




#===================================================

##### INPUT #####

# filename
fName <- "./restart_25km/mHM_restart_001.nc"

# Variable name from netcdf
var <- "L1_soilMoistSat" # L1_kfastFlow L1_kBaseFlow L1_soilMoistSat L1_aETSoil

# Color scheme (check DEFINE COLOR section below for the color numbers)
clr_index <- 11 # 1 to 12 (check file colormaps.R, the colors are stored there!)

# Reverse color?
clr_rev <- FALSE # TRUE or FALSE

#===================================================




# Check whether file exists in current location
if (!file.exists(fName)){
  stop(paste("file not found. Make sure the file name and path provided (", fName, ") is correct", sep = " "))
}

# Get full set of color maps
clr_set <- get_colors( clr_index, clr_rev )






# (2.1) PROCESS ===================


# Open the netCDF file
ncin <- nc_open(fName)

# Check whether the variable exists in the file
if ( !var %in% names(ncin$var) ){
  stop(paste("variable not found. Make sure the variablee", var, "is in file", fName, sep = " "))
}

# Get the selected variable
var.array <- ncvar_get(ncin,var)
dunits<- ncatt_get(ncin,var,"unit") 
var_longname <- ncatt_get(ncin,var,"long_name") 

# Check the dimensions of the variable
ndims <- length(dim(var.array))




# get LAT LON (for 2d latlon!)
lon <- ncvar_get(ncin,"L1_domain_lon") 
lat <- ncvar_get(ncin,"L1_domain_lat") 
lat <- lat[nrow(lat):1, ] # comment out if latitude flipping is NOT desired!

# check for Western hemisphere
if (lon[1,1] > lon[1,ncol(lon)]) {
  lon <- lon[ncol(lon):1, ]
}

# Close the netCDF file
nc_close(ncin)








# (3.1) GRAPH ===================


# Check latlon for non-rectangular grids
if (lat[1,1] != lat[1,2]){
  # lat is varying in both directions i.e. non-rectangular grids
  lat_set <- matrix(rep(seq(1, length(lat[,1])), length(lat[1,])), nrow = length(lat[,1]), byrow = F)
  lon_set <- matrix(rep(seq(1, length(lat[1,])), length(lat[,1])), nrow = length(lat[,1]), byrow = T)
  lat_name <- "y"
  lon_name <- "x"
} else {
  lat_set <- lat
  lon_set <- lon
  lat_name <- "latitudes"
  lon_name <- "longitudes"
}



### 2D plots ###
if (ndims == 2){
  
  # Plot 2d
  mapplot <- levelplot(var.array ~ lon_set * lat_set, margin=FALSE, 
                       main = paste(var_longname$value), 
                       par.settings=list(panel.background=list(col="grey90")), 
                       col.regions = clr_set,
                       pretty=T, xlab = lon_name, ylab = lat_name, aspect = "iso")
  # Output
  pdf( file=paste("restart_map_", var, ".pdf", sep = ""), width = 8, height = 8)
  print(mapplot)
  dev.off()
}





# We need constant color map for 3d and 4d variables. Get the upper and lower bounds for the values.
ubound <- max(var.array, na.rm = T)
lbound <- min(var.array, na.rm = T)



### 3D plots ###
if (ndims == 3){
  
  # Plot 3d
  
  # Open the PDF to write to
  pdf( file=paste("restart_map_", var, ".pdf", sep = ""), width = 8, height = 8, onefile = TRUE)
  
  # Get 3rd dimension name
  d3_name <- eval(parse(text=paste("ncin$var$",var,"$dim[[3]]$name", sep = "")))
  
  # loop over 3rd dim
  for (d3 in seq(1, dim(var.array)[3])){
    
    mapplot <- levelplot(var.array[,,d3] ~ lon_set * lat_set, margin=FALSE, 
                         at=rev(seq(lbound, ubound, length.out = length(clr_set))), 
                         main = paste(var_longname$value, "\n", d3_name, " = ", d3, sep = ""),
                         par.settings=list(panel.background=list(col="grey90")), 
                         col.regions =clr_set,
                         pretty=T, xlab = lon_name, ylab = lat_name, aspect = "iso")
    print(mapplot)
  }
  
  # Close the writing to PDF
  dev.off()
}



### 4D plots ###
if (ndims == 4){
  
  # Plot 4D
  
  # Open the PDF to write to
  pdf( file=paste("restart_map_", var, ".pdf", sep = ""), width = 8, height = 8, onefile = TRUE)
  
  
  # Get 3rd and 4th dimension names
  d3_name <- eval(parse(text=paste("ncin$var$",var,"$dim[[3]]$name", sep = "")))
  d4_name <- eval(parse(text=paste("ncin$var$",var,"$dim[[4]]$name", sep = "")))
  
  
  # loop over 4th dim
  for (d4 in seq(1, dim(var.array)[4])){
    
    # loop over 3rd dim
    for (d3 in seq(1, dim(var.array)[3])){
    
      mapplot <- levelplot(var.array[,,d3,d4] ~ lon_set * lat_set, margin=FALSE, 
                           at=seq(lbound, ubound, length.out = length(clr_set)), 
                           main = paste(var_longname$value, "\n", d3_name, " = ", d3, "\n", d4_name, " = ", d4, sep = ""),
                           par.settings=list(panel.background=list(col="grey90")), 
                           col.regions =clr_set,
                           pretty=T, xlab = lon_name, ylab = lat_name, aspect = "iso")
      print(mapplot)
    }
  }
  
  # Close the writing to PDF
  dev.off()
  
}


