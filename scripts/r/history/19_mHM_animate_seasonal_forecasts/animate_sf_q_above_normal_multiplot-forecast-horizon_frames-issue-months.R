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
iopath_parent <- "/Users/shresthp/Nextcloud/Cloud/macbook/01_work/Keynote/SaWaM/GRoW_FinalConf/2019/"

# Above normal flow Q colors
clr_vector   <-    c("#004D7F", "#1C86EE", "#00BFFF", "#F8BA00", "#FF6347")

# General control parameters
nIssueMonth <- 6
nDomains <- 1
nForecastHorizon <- 6
IssueMonth <- c( "20190115_20190715", "20190215_20190815", "20190315_20190915",
                 "20190415_20191015", "20190515_20191115", "20190615_20191215")
# Domains <- c( "sf_basin",  "khuzestan", "tabn" )
# DomainNames <- c( "saofrancisco",  "khuzestan", "tekeze_atbara_bluenile" )
# DomainIds <- c( "2000000", "1000000", "3000000")
Domains <- c( "tabn" )
DomainNames <- c( "tekeze_atbara_bluenile" )
DomainIds <- c( "3000000")
TrackingMonthIndex <- 6 # also used for baseline
TrackingMonth <- "20190615_20190615"

# Initial file check for time
fName = paste( iopath_parent, Domains[1], "/frcst/raster/hydrol/", DomainIds[1], 
               "_frcst_raster_hydrol_monthly_q_ufz_mhm_v1.0_e1_", IssueMonth[1], ".nc", sep="")
ncin <- nc_open(fName)
nctime <- ncvar_get(ncin,"time")
nt <- dim(nctime)



# ### GIF generation
# # -----------------------
#   # make sure ImageMagick has been installed in your system
#   saveGIF({
    
    #### PDF generation
    # -----------------------
    pdf( paste(iopath_parent, "q_above_normal_probab_multiplot.pdf", sep = ""), width = 19, height = 6)  # Uncomment for pdf generation

    # Initialize
    p <- list() # Defining p as list
    nColPlot <- nForecastHorizon + 1 # 1 extra is for the baseline
    nRowPlot <- nDomains
    
    
    
    for (iIssueMonth in 1:nIssueMonth) { # Issue month loop
      
      for (iDomain in 1:nDomains) {    # Domain loop
        
        
        
        #===== FORECASTS ======
        # Forecast File
        fName = paste( iopath_parent, Domains[iDomain], "/frcst/raster/hydrol/", DomainIds[iDomain], 
                       "_frcst_raster_hydrol_monthly_q_ufz_mhm_v1.0_e1_", IssueMonth[iIssueMonth], ".nc", sep="")
        
        
        #### Read the netCDF file
        #-----------------------
        ncin <- nc_open(fName)
        
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
        tmp.array <- ncvar_get(ncin,"q_above_normal_probab") # dimensions (row=lon,col=lat,time) 
        
        
        for (iForecastHorizon in 1:nForecastHorizon) { # Forecast horizon loop
          
          # Setup plot environment
          grid <- expand.grid(lon=lon, lat=lat)
          cutpts <- c (0, 20, 40, 60, 80, 100)
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
                              col.regions=rev(clr_vector), xlab = "", ylab = "",
                              colorkey =FALSE,
                              par.settings=list(panel.background=list(col="#909090")),
                              main=list(label=fHeader, fontsize=20, col = color_select),
                              scales=list(col = 'transparent'),
                              margin=FALSE,
                              strip.border = list(col = 'transparent'))
          
          # Save plot as an element of multiplot
          xplot = gridExtra:::latticeGrob(myplot)
          p[[ nForecastHorizon*(iDomain-1) + iForecastHorizon]] <- xplot
          
        }
      }
      
      # Determine the layout of multiplot
      xlay <- matrix(c(NA, 1:(nColPlot*nRowPlot)), nRowPlot, nColPlot, byrow = TRUE)
      
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
  # }, movie.name = paste(iopath_parent, "q_above_normal_probab_multiplot.gif", sep = ""),
  # interval = 2, nmax = 50, ani.width = 1400, ani.height = 400)


dev.off() # Uncomment for pdf generation

