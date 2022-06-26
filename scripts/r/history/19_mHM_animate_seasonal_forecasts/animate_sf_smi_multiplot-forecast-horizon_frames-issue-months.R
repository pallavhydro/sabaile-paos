#####################################################################################
##                   ----------------------------------------------------------------
## ==================== GIF maker for SMI output netCDF files (Ensemble Multiplot version)
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
# library(DescTools)
library(chron)
library(plyr)
library(lattice)
library(animation)
library(gridExtra)  # for using "grid.arrange" function
library(grid)

# Path
# iopath_parent <- "/Users/shresthp/Desktop/dss_june2020/sample_08_07_2020/" 
iopath_parent <- "/Users/shresthp/Nextcloud/Cloud/macbook/01_work/Keynote/SaWaM/GRoW_FinalConf/2015/"

# SMI colors
clr_vector   <-    c("#730000", "#E60000", "#FFAA00", "#FCD37F", "#FFFE01", "#FFFFFF")

# General control parameters
nIssueMonth <- 8
nDomains <- 1
nForecastHorizon <- 6
IssueMonth <- c( "20150115_20150715", "20150215_20150815", "20150315_20150915",
                 "20150415_20151015", "20150515_20151115", "20150615_20151215",
                 "20150715_20160115", "20150815_20160215", "20150915_20160315",
                 "20151015_20160415", "20151115_20160515", "20151215_20160615" )
# Domains <- c( "sf_basin",  "khuzestan", "tabn" )
# DomainNames <- c( "saofrancisco",  "khuzestan", "tekeze_atbara_bluenile" )
# DomainIds <- c( "2000000", "1000000", "3000000")
Domains <- c( "tabn" )
DomainNames <- c( "tekeze_atbara_bluenile" )
DomainIds <- c( "3000000")
TrackingMonthIndex <- 8 # also used for baseline
TrackingMonth <- "20150815_20150815"

# Initial file check for time
fName = paste( iopath_parent, Domains[1], "/frcst/raster/drought/", DomainIds[1], 
               "_frcst_raster_drought_monthly_smi1_ufz_mhm-smi_v1.0_e1_", IssueMonth[1], ".nc", sep="")
ncin <- nc_open(fName)
nctime <- ncvar_get(ncin,"time")
nt <- dim(nctime)



# ### GIF generation
# # -----------------------
# # make sure ImageMagick has been installed in your system
# saveGIF({

#### PDF generation
# -----------------------
pdf( paste(iopath_parent, "smi1_ensemble_median_multiplot.pdf", sep = ""), width = 19, height = 6)  # Uncomment for pdf generation
  
  # Initialize
  p <- list() # Defining p as list
  nColPlot <- nForecastHorizon + 1 # 1 extra is for the baseline
  nRowPlot <- nDomains
  
  
  
  for (iIssueMonth in 1:nIssueMonth) { # Issue month loop
    
    for (iDomain in 1:nDomains) {    # Domain loop
      
      
      
      #===== BASELINE ======
      
      if (iIssueMonth == 1){
        
        # Baseline File
        bName = paste( iopath_parent, Domains[iDomain], "/hist/raster/", DomainIds[iDomain], 
                       "_hist_raster_drought_monthly_smi1_ufz_mhm-smi_v1.0_e1_", TrackingMonth, ".nc", sep="")
        
        #### Read the netCDF file
        #-----------------------
        ncin <- nc_open(bName)
        
        # get LAT LON
        lon <- ncvar_get(ncin,"lon") 
        nlon <- length(lon)
        lat <- ncvar_get(ncin,"lat") 
        nlat <- length(lat) 
        
        lat <- rev(lat) # flipping needed for mHM output netCDFs!
        
        # check for Western hemisphere
        if (lon[1] > tail(lon, n=1)) {
          lon <- rev(lon)
        }
        
        # get TIME variable and attributes 
        nctime <- ncvar_get(ncin,"time")
        tunits <- ncatt_get(ncin,"time","units") 
        
        tustr <- strsplit(tunits$value, " ")
        tdstr <- strsplit(unlist(tustr)[3], "-")
        tmonth <- as.integer(unlist(tdstr)[2])
        tday <- as.integer(unlist(tdstr)[3])
        tyear <- as.integer(unlist(tdstr)[1])
        tfinal <- chron(nctime, origin=c(tmonth,tday, tyear))
        tfirst <- chron(0, origin=c(tmonth,tday, tyear))
        
        # get VARIABLE and its attributes 
        tmp.array <- ncvar_get(ncin,"smi1") # dimensions (row=lon,col=lat,time) 
        
        # Setup plot environment
        grid <- expand.grid(lon=lon, lat=lat)
        cutpts <- c (0, 0.02, 0.05, 0.1, 0.2, 0.3, 1)
        x.scale <- list(at=seq(floor(min(lon)),ceiling(max(lon)),1))
        y.scale <- list(at=seq(floor(min(lat)),ceiling(max(lat)),1))
        
        # Setup plot data and plot
        tmp.slice <- tmp.array[,ncol(tmp.array):1] # flipping the latitude values as "lat" was flipped
        
        # Plot baseline
        myplot <- levelplot(tmp.slice ~ lon * lat, data=grid, aspect = "iso", pretty=T, at=cutpts,
                            col.regions=clr_vector, xlab = "", ylab = "",
                            colorkey =FALSE,
                            par.settings=list(panel.background=list(col="#909090")),
                            main=list(label=paste("Baseline \n\n", "L0 . ",  months(chron(nctime[1], origin=c(tmonth,tday, tyear)), abbreviate = TRUE), " \n", sep = ""), 
                                      fontsize=20, col = "blue"),
                            scales=list(col = 'transparent'),
                            margin=FALSE,
                            strip.border = list(col = 'transparent'))
        
        # Save plot as an element of multiplot
        xplot = gridExtra:::latticeGrob(myplot)
        p[[iDomain + nForecastHorizon*(iDomain-1)]] <- xplot
        
      }
      
      
      
      
      #===== FORECASTS ======
      # Forecast File
      fName = paste( iopath_parent, Domains[iDomain], "/frcst/raster/drought/", DomainIds[iDomain], 
                     "_frcst_raster_drought_monthly_smi1_ufz_mhm-smi_v1.0_e1_", IssueMonth[iIssueMonth], ".nc", sep="")
      
      
      #### Read the netCDF file
      #-----------------------
      ncin <- nc_open(fName)
      
      # get LAT LON
      # already done for baseline file!
      
      # check for Western hemisphere
      # already done for baseline file!
      
      # get TIME variable and attributes 
      nctime <- ncvar_get(ncin,"time")
      tunits <- ncatt_get(ncin,"time","units") 
      
      tustr <- strsplit(tunits$value, " ")
      tdstr <- strsplit(unlist(tustr)[3], "-")
      tmonth <- as.integer(unlist(tdstr)[2])
      tday <- as.integer(unlist(tdstr)[3])
      tyear <- as.integer(unlist(tdstr)[1])
      tfinal <- chron(nctime, origin=c(tmonth,tday, tyear))
      tfirst <- chron(0, origin=c(tmonth,tday, tyear))
      
      # get VARIABLE and its attributes 
      tmp.array <- ncvar_get(ncin,"smi1_ensemble_median") # dimensions (row=lon,col=lat,time) 
        
        
      for (iForecastHorizon in 1:nForecastHorizon) { # Forecast horizon loop
          
        # Setup plot environment
        x.scale <- list(at=seq(floor(min(lon)),ceiling(max(lon)),1))
        y.scale <- list(at=seq(floor(min(lat)),ceiling(max(lat)),1))
        
        # Setup plot data and plot
        tmp.slice <- tmp.array[, , iForecastHorizon]
        tmp.slice <- tmp.slice[,ncol(tmp.slice):1] # flipping the latitude values as "lat" was flipped
        
        # Highlight the month being tracked
        curr_month <- as.integer(months(chron(nctime[iForecastHorizon], origin=c(tmonth,tday, tyear))))
        if (curr_month == TrackingMonthIndex) {
          color_select = "blue"
        } else {
          color_select = "black"
        }
        
        if (iForecastHorizon == 1) {
          fHeader = paste("Forecasts \n\n", "L", iForecastHorizon, " . ", months(chron(nctime[iForecastHorizon], origin=c(tmonth,tday, tyear)), abbreviate = TRUE), "\n (issue month)", sep = "")
        } else {
          fHeader = paste(" \n\n", "L", iForecastHorizon, " . ", months(chron(nctime[iForecastHorizon], origin=c(tmonth,tday, tyear)), abbreviate = TRUE), " \n", sep = "")
        }
  
        
        myplot <- levelplot(tmp.slice ~ lon * lat, data=grid, aspect = "iso", pretty=T, at=cutpts,
                            col.regions=clr_vector, xlab = "", ylab = "",
                            colorkey =FALSE,
                            par.settings=list(panel.background=list(col="#909090")),
                            main=list(label=fHeader, fontsize=20, col = color_select),
                            scales=list(col = 'transparent'),
                            margin=FALSE,
                            strip.border = list(col = 'transparent'))
        
        # Save plot as an element of multiplot
        xplot = gridExtra:::latticeGrob(myplot)
        p[[iDomain + nForecastHorizon*(iDomain-1) + iForecastHorizon]] <- xplot
  
      }
    }
    
    # Determine the layout of multiplot
    xlay <- matrix(c(1:(nColPlot*nRowPlot)), nRowPlot, nColPlot, byrow = TRUE)
    
    select_grobs <- function(lay) {
      id <- unique(c(t(lay))) # transpose ON if byrow = TRUE in xlay! If not, remove transpose!
      # id <- unique(c(lay))
      id[!is.na(id)]
    }
    

    mymultiplot <- grid.arrange(grobs=p[select_grobs(xlay)], layout_matrix=xlay,
                                # top = textGrob(paste("Issue Month:", months(tfirst), years(tfinal[iForecastHorizon]), "\n", sep=" "), 
                                #                hjust = 2.5, gp=gpar(fontsize=25,font="Helvetica")),
                                bottom = textGrob(expression(paste(bold("mHM"), " simulations (PK Shrestha, L Samaniego, O Rakovec. Helmholtz Centre for Environmental Research - UFZ)", sep = "")), 
                                                  hjust = 0.35, gp=gpar(fontsize=20,font="Helvetica")))
    
    print(mymultiplot)
    

      
  }
# }, movie.name = paste(iopath_parent, "smi1_ensemble_median_multiplot.gif", sep = ""),
#   interval = 2, nmax = 50, ani.width = 1400, ani.height = 400)

  
dev.off() # Uncomment for pdf generation

