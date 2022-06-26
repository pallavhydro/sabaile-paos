#####################################################################################
##                   -------------------------------------------
## ================== Animator for mHM output netCDF files v2  =====================
##                   -------------------------------------------
##   
##  Code developer:    Pallav Kumar Shrestha    (pallav-kumar.shrestha@ufz.de)
##                     10 May 2019
##
##
##  Usage: 
##        
##        Rscript animate2 <variable> <color distribution> <flip color>
##
##        <variable>            : SM_Lall, Q, Qrouted, ...
##        <color distribution>  : high, low, linear
##        <flip color>          : yes, no
##
## --- Reference: https://sites.google.com/view/climate-access-cooperative/code?authuser=0
##
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
fName1 = "mHM_Fluxes_States.nc"
fName2 = "mRM_Fluxes_States.nc"

# Command line arguments
args <- commandArgs(trailingOnly = TRUE)
var <- as.character(args[1])
clr_cut <- as.character(args[2])
clr_dir <- as.character(args[3])


#### Read the netCDF files
#-----------------------

# mHM Flux States -----
ncin1 <- nc_open(fName1)

# get LAT LON
lon1 <- ncvar_get(ncin1,"lon") 
lon1 <- lon1[,1] # we just need a vector of values in the direction in which lon changes
nlon1 <- length(lon1)
lat1 <- ncvar_get(ncin1,"lat") 
lat1 <- lat1[1,] # we just need a vector of values in the direction in which lat changes
nlat1 <- length(lat1) 

lat1 <- rev(lat1) # latitude flipping needed for mHM output netCDFs!

# check for Western hemisphere
if (lon1[1] > tail(lon1, n=1)) {
  lon1 <- rev(lon1)
}


# mRM Flux States ----
ncin2 <- nc_open(fName2)

# get LAT LON
lon2 <- ncvar_get(ncin2,"lon") 
lon2 <- lon2[,1] # we just need a vector of values in the direction in which lon changes
nlon2 <- length(lon2)
lat2 <- ncvar_get(ncin2,"lat") 
lat2 <- lat2[1,] # we just need a vector of values in the direction in which lat changes
nlat2 <- length(lat2) 

lat2 <- rev(lat2) # latitude flipping needed for mHM output netCDFs!

# check for Western hemisphere
if (lon2[1] > tail(lon2, n=1)) {
  lon2 <- rev(lon2)
}



# get TIME variable and attributes 
nctime <- ncvar_get(ncin1,"time")
tunits <- ncatt_get(ncin1,"time","units") 
nt <- dim(nctime) 

tustr <- strsplit(tunits$value, " ")
tdstr <- strsplit(unlist(tustr)[3], "-")
tmonth <- as.integer(unlist(tdstr)[2])
tday <- as.integer(unlist(tdstr)[3])
tyear <- as.integer(unlist(tdstr)[1])
tfinal <- chron(nctime/24, origin=c(tmonth, tday, tyear)) # nctime (hours) is converted to days



# variable loop starts HERE

# If loop to switch between ncin1 and ncin2


# get VARIABLE and its attributes 
tmp.array <- ncvar_get(ncin1,var) # dimensions (row=lon,col=lat,time) 
dlname <- ncatt_get(ncin1,var,"long_name") 
dunits<- ncatt_get(ncin1,var,"unit") 


# Prepare grid, color and date
grid <- expand.grid(lon=lon1, lat=lat1)
x.scale <- list(at=seq(floor(min(lon1)),ceiling(max(lon1)),2))
y.scale <- list(at=seq(floor(min(lat1)),ceiling(max(lat1)),2))

flr <- floor(min(tmp.array[,,], na.rm = TRUE))
cel <- ceiling(max(tmp.array[,,], na.rm = TRUE))
  
  # color cut points 
if (clr_cut == "low") {
  cutpts <- 1 - log(seq(1, 12))/log(12) # low
} else if (clr_cut == "high") {
  cutpts <- log(seq(1, 12))/log(12) # high
} else {
  cutpts <- seq(1, 12)/12 # linear
}
cutpts <- flr + cutpts*(cel-flr)

  # color direction
if (clr_dir == "yes") {
  color_direction = rev(brewer.pal(11,"RdYlBu")) # reversed
} else {
  color_direction = brewer.pal(11,"RdYlBu") # normal
}

  # date ribbon
temp_res_check <- tfinal[2] - tfinal[1]
print(temp_res_check)

#### GIF generation
#-----------------------
## make sure ImageMagick has been installed in your system
saveGIF({
  for (i in 1:nt) {
    
    # date ribbon
    if (temp_res_check <= 1) {
      date_ribbon <- paste(days(tfinal[i]), months(tfinal[i]), years(tfinal[i]), sep=" ") # date ribbon for daily data
    } else if (temp_res_check > 31) {
      date_ribbon <- paste(years(tfinal[i]),sep = " ") # date ribbon for yearly data
    } else {
      date_ribbon <- paste(months(tfinal[i]), years(tfinal[i]), sep=" ") # date ribbon for monthly data
    }
    
    tmp.slice <- tmp.array[, , i]
    tmp.slice <- tmp.slice[,ncol(tmp.slice):1] # flipping the latitude values as "lat" was flipped
    myplot <- levelplot(tmp.slice ~ lon * lat, data=grid, pretty=T, at=cutpts,
                        col.regions=color_direction, xlab = "", ylab = "",
                        sub=paste(dlname$value, "\n", dunits$value, sep=""),
                        main=date_ribbon,
                        scales=list(x=x.scale, tck=c(-1,-1), y=y.scale)) 
    print(myplot)
  }
}, movie.name = paste(fName,".gif", sep=""), interval = 0.01, nmax = 500)


#### PDF generation
#-----------------------

pdf( paste(fName,".pdf", sep=""), width = 4, height = 4)
for (i in 1:nt) {
  
  # date ribbon
  if (temp_res_check <= 1) {
    date_ribbon <- paste(days(tfinal[i]), months(tfinal[i]), years(tfinal[i]), sep=" ") # date ribbon for daily data
  } else if (temp_res_check > 31) {
    date_ribbon <- paste(years(tfinal[i]),sep = " ") # date ribbon for yearly data
  } else {
    date_ribbon <- paste(months(tfinal[i]), years(tfinal[i]), sep=" ") # date ribbon for monthly data
  }
  
  tmp.slice <- tmp.array[, , i]
  tmp.slice <- tmp.slice[,ncol(tmp.slice):1] # flipping the latitude values as "lat" was flipped
  myplot <- levelplot(tmp.slice ~ lon * lat, data=grid, pretty=T, at=cutpts,
                      col.regions=color_direction, xlab = "", ylab = "",
                      sub=paste(dlname$value, "\n", dunits$value, sep=""),
                      main=date_ribbon,
                      scales=list(x=x.scale, tck=c(-1,-1), y=y.scale)) 
  print(myplot)
}
dev.off()






