#####################################################################################
##                   ----------------------------------------------------------------
## ========================= GIF maker for mHM output netCDF files
##                   ----------------------------------------------------------------
## --- Code developer: 
## ------------------  Pallav Kumar Shrestha pallav-kumar.shrestha@ufz.de ------
## ------------------  10 May 2019 ---------------------------------------------
##
## --- Reference: https://sites.google.com/view/climate-access-cooperative/code?authuser=0
#####################################################################################


# Open libraries/ packages
library(ggplot2)
library(ncdf4) 
library(graphics) 
library(RColorBrewer)
library(DescTools)
library(chron)
library(plyr)
library(lattice)
library(animation)

# Parameters
fName = "mRM_Fluxes_States.nc"



#### Read the netCDF file
#-----------------------
ncin <- nc_open(fName)

# get LAT LON
lon <- ncvar_get(ncin,"lon") 
lon <- lon[,1] # we just need a vector of values in the direction in which lon changes
nlon <- length(lon)
lat <- ncvar_get(ncin,"lat") 
lat <- lat[1,] # we just need a vector of values in the direction in which lat changes
nlat <- length(lat) 

lat <- rev(lat) # flipping needed for mHM output netCDFs!

# check for Western hemisphere
if (lon[1] > tail(lon, n=1)) {
  lon <- rev(lon)
}

# get TIME variable and attributes 
nctime <- ncvar_get(ncin,"time")
tunits <- ncatt_get(ncin,"time","units") 
nt <- dim(nctime) 

tustr <- strsplit(tunits$value, " ")
tdstr <- strsplit(unlist(tustr)[3], "-")
tmonth <- as.integer(unlist(tdstr)[2])
tday <- as.integer(unlist(tdstr)[3])
tyear <- as.integer(unlist(tdstr)[1])
tfinal <- chron(nctime/24, origin=c(tday, tmonth, tyear)) # nctime (hours) is converted to days

# get VARIABLE and its attributes 
tmp.array <- ncvar_get(ncin,"Qrouted") # dimensions (row=lon,col=lat,time) 
dlname <- ncatt_get(ncin,"Qrouted","long_name") 
dunits<- ncatt_get(ncin,"Qrouted","units") 
fillvalue <- ncatt_get(ncin,"Qrouted","_FillValue") 

# get GLOBAL attributes 
title <- ncatt_get(ncin,0,"title") 
institution <- ncatt_get(ncin,0,"institution") 
datasource <- ncatt_get(ncin,0,"source") 
references <- ncatt_get(ncin,0,"references") 
history <- ncatt_get(ncin,0,"history") 
Conventions <- ncatt_get(ncin,0,"Conventions") 


grid <- expand.grid(lon=lon, lat=lat)

cutpts <- 1 - log(seq(1, 12))/log(12)

flr <- floor(min(tmp.array[,,], na.rm = TRUE))
cel <- ceiling(max(tmp.array[,,], na.rm = TRUE))

cutpts <- rev(flr + cutpts*(cel-flr))

x.scale <- list(at=seq(floor(min(lon)),ceiling(max(lon)),2))
y.scale <- list(at=seq(floor(min(lat)),ceiling(max(lat)),2))


#### GIF generation
#-----------------------
## make sure ImageMagick has been installed in your system
saveGIF({
  for (i in 1:nt) {
    tmp.slice <- tmp.array[, , i]
    tmp.slice <- tmp.slice[,ncol(tmp.slice):1] # flipping the latitude values as "lat" was flipped
    myplot <- levelplot(tmp.slice ~ lon * lat, data=grid, pretty=T, at=cutpts,
                        col.regions=rev(brewer.pal(11,"RdYlBu")), xlab = "", ylab = "",
                        sub="mHM simulated Routed Flow (m3.s-1)  \n mHM simulations at 0.015625 deg (< 2km)",
                        main=paste(months(tfinal[i]), years(tfinal[i]), sep=" "),
                        scales=list(x=x.scale, tck=c(-1,-1), y=y.scale))
    print(myplot)
  }
}, movie.name = "mHM_Qrouted.gif", interval = 0.5, nmax = 50)


#### PDF generation
#-----------------------

pdf( "mHM_Qrouted.pdf", width = 4, height = 4)
for (i in 1:nt) {
  tmp.slice <- tmp.array[, , i]
  tmp.slice <- tmp.slice[,ncol(tmp.slice):1] # flipping the latitude values as "lat" was flipped
  myplot <- levelplot(tmp.slice ~ lon * lat, data=grid, pretty=T, at=cutpts,
                      col.regions=rev(brewer.pal(11,"RdYlBu")), xlab = "", ylab = "",
                      sub="mHM simulated Routed Flow (m3.s-1)  \n mHM simulations at 0.015625 deg (< 2km)",
                      main=paste(months(tfinal[i]), years(tfinal[i]), sep=" "),
                      scales=list(x=x.scale, tck=c(-1,-1), y=y.scale))
  print(myplot)
}
dev.off()






