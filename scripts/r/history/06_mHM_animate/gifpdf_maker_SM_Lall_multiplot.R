#####################################################################################
##                   ----------------------------------------------------------------
## ========================= GIF maker for mHM output netCDF files (MULTIPLOT version)
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
library(gridExtra)  # for using "grid.arrange" function
library(grid)



# General control parameters
nDomain <- 2
nParam <- 5
Domain <- c( "D01", "D02" )
Param <- c( "control_run", "PR02", "PR04", "PR06", "PR08")

# Initial file check for time
fName = paste( Domain[1], "/", Param[1], "/mHM_Fluxes_States.nc", sep="")
ncin <- nc_open(fName)
nctime <- ncvar_get(ncin,"time")
nt <- dim(nctime)

#### GIF generation
#-----------------------
## make sure ImageMagick has been installed in your system
saveGIF({   # Uncomment for gif generation    # Initiantlize
  p <- list() # Defining p as list

  for (t in 1:nt) {    # Uncomment for gif generation
    
    
### PDF generation
# -----------------------
# pdf( "mHM_SM_Lall.pdf", width = 16, height = 6)  # Uncomment for pdf generation
# for (t in 1:nt) { # Uncomment for pdf generation

    
    for (i in 1:nDomain) { # Domain loop
      for (j in 1:nParam) { # Parameter loop
    
        # Parameters
        fName = paste( Domain[i], "/", Param[j], "/mHM_Fluxes_States.nc", sep="")
        
        
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
        tfinal <- chron(nctime/24., origin=c(tmonth,tday, tyear)) # nctime (hours) is converted to days
        
        # get VARIABLE and its attributes 
        tmp.array <- ncvar_get(ncin,"SM_Lall") # dimensions (row=lon,col=lat,time) 
        dlname <- ncatt_get(ncin,"SM_Lall","long_name") 
        dunits<- ncatt_get(ncin,"SM_Lall","units") 
        fillvalue <- ncatt_get(ncin,"SM_Lall","_FillValue") 
        
        # get GLOBAL attributes 
        title <- ncatt_get(ncin,0,"title") 
        institution <- ncatt_get(ncin,0,"institution") 
        datasource <- ncatt_get(ncin,0,"source") 
        references <- ncatt_get(ncin,0,"references") 
        history <- ncatt_get(ncin,0,"history") 
        Conventions <- ncatt_get(ncin,0,"Conventions") 
        
        # Setup plot environment
        grid <- expand.grid(lon=lon, lat=lat)
        cutpts <- log(seq(1, 12))/log(12)
        x.scale <- list(at=seq(floor(min(lon)),ceiling(max(lon)),1))
        y.scale <- list(at=seq(floor(min(lat)),ceiling(max(lat)),1))
        
        # Setup plot data and plot
        tmp.slice <- tmp.array[, , t]
        tmp.slice <- tmp.slice[,ncol(tmp.slice):1] # flipping the latitude values as "lat" was flipped
  
        
        myplot <- levelplot(tmp.slice ~ lon * lat, data=grid, aspect = "iso", pretty=T, at=cutpts,
                            col.regions=brewer.pal(11,"RdYlBu"), xlab = "", ylab = "",
                            main=paste(Domain[i], Param[j], sep = "-"),
                            scales=list(x=x.scale, tck=c(-1,-1), y=y.scale), colorkey = TRUE) 
        
        # Save plot as an element of multiplot
        xplot = gridExtra:::latticeGrob(myplot)
        p[[nParam*(i-1)+j]] <- xplot
  
      }
    }
    
    # Determine the layout of multiplot
    xlay <- matrix(c(1,2,3,4,5,6,7,8,9,10), ncol = 2, byrow = FALSE) 

    select_grobs <- function(lay) {
      id <- unique(c(lay)) 
      id[!is.na(id)]
    }
    

    mymultiplot <- grid.arrange(grobs=p[select_grobs(xlay)], layout_matrix=xlay,
                                top = textGrob(paste("\n mHM.Chira
# Seasonal Hydrological Forecasts - Soil Moisture
# Issue Date: 1 Jan 1983    Forecast Month:", months(tfinal[t]), 
years(tfinal[t]),"\n", sep=" "),
                                gp=gpar(fontsize=20,font="Helvetica", just="left")))
    
    print(mymultiplot)

# }  # Uncomment for pdf generation
# dev.off() # Uncomment for pdf generation
      
  }
}, movie.name = "mHM_SM_Lall_multiplot.gif", interval = 2, nmax = 50, ani.width = 800, ani.height = 1200)



