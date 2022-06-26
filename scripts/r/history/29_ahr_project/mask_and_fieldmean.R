#####################################################################################
##                   ----------------------------------------------------------------
## ==================== Mask and Field Mean in R
##                   ----------------------------------------------------------------
## --- Code developer: 
## ------------------  Pallav Kumar Shrestha pallav-kumar.shrestha@ufz.de ------
## ------------------  29 Sep 2021 ---------------------------------------------
##
##
##
##                Note: "The mask and the data should have same extents"
##
## --- Mods: 
##          xx xxx xxxx - xxx
#####################################################################################


# Open libraries/ packages
library(ncdf4) 


# ====================== I) CONTROL =======================

# Path to Mask file
mask_file="./mask/mask_processed_germany_extent.nc"

# Path to file to be masked
data_file= "./pre.nc"

# Variable of Interest
varname = "pre"




# ====================== II) READ =======================

# ====================== The MASK
# Read mask
# Read the netCDF file
ncin <- nc_open(mask_file)
# get VARIABLE
mask<- ncvar_get(ncin,"mask")  # [lon, lat]



# ====================== The file to be MASKED
# Read ERA5 data
# Read the netCDF file
ncin <- nc_open(data_file)
# get VARIABLE
data_3d <- ncvar_get(ncin, varname)  # [lon, lat, time]
# Read time attribute
nctime <- ncvar_get(ncin,"time")
nt <- dim(nctime)





# ====================== III) PROCESS =======================

# initialize
data_3d_masked_fldmean <- vector()

for (itime in 1:nt){
  
  # MASK
  data_3d[,,itime] <- ifelse(mask < 0, NA, data_3d[,,itime])
  
  # FLDMEAN
  data_3d_masked_fldmean[itime] <- mean(data_3d[,,itime], na.rm = TRUE)
  
}



# ====================== IV) PLOT =======================

plot(data_3d_masked_fldmean)
