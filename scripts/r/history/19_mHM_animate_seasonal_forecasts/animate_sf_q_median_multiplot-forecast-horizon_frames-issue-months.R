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

# Q colors (NCV Jet)
clr_vector   <- c("#00007F","#000083","#000087","#00008B","#00008F","#000093","#000097","#00009B","#00009F","#0000A3","#0000A7","#0000AB","#0000AF","#0000B3","#0000B7","#0000BB","#0000BF","#0000C3","#0000C7","#0000CB","#0000CF","#0000D3","#0000D7","#0000DB","#0000DF","#0000E3","#0000E7","#0000EB","#0000EF","#0000F3","#0000F7","#0000FB","#0000FF","#0004FF","#0008FF","#000CFF","#0010FF","#0014FF","#0018FF","#001CFF","#0020FF","#0024FF","#0028FF","#002CFF","#0030FF","#0034FF","#0038FF","#003CFF","#0040FF","#0044FF","#0048FF","#004CFF","#0050FF","#0054FF","#0058FF","#005CFF","#0060FF","#0064FF","#0068FF","#006CFF","#0070FF","#0074FF","#0078FF","#007CFF","#0080FF","#0084FF","#0088FF","#008CFF","#0090FF","#0094FF","#0098FF","#009CFF","#00A0FF","#00A4FF","#00A8FF","#00ACFF","#00B0FF","#00B4FF","#00B8FF","#00BCFF","#00C0FF","#00C4FF","#00C8FF","#00CCFF","#00D0FF","#00D4FF","#00D8FF","#00DCFF","#00E0FF","#00E4FF","#00E8FF","#00ECFF","#00F0FF","#00F4FF","#00F8FF","#00FCFF","#01FFFD","#05FFF9","#09FFF5","#0DFFF1","#11FFED","#15FFE9","#19FFE5","#1DFFE1","#21FFDD","#25FFD9","#29FFD5","#2DFFD1","#31FFCD","#35FFC9","#39FFC5","#3DFFC1","#41FFBD","#45FFB9","#49FFB5","#4DFFB1","#51FFAD","#55FFA9","#59FFA5","#5DFFA1","#61FF9D","#65FF99","#69FF95","#6DFF91","#71FF8D","#75FF89","#79FF85","#7DFF81","#81FF7D","#85FF79","#89FF75","#8DFF71","#91FF6D","#95FF69","#99FF65","#9DFF61","#A1FF5D","#A5FF59","#A9FF55","#ADFF51","#B1FF4D","#B5FF49","#B9FF45","#BDFF41","#C1FF3D","#C5FF39","#C9FF35","#CDFF31","#D1FF2D","#D5FF29","#D9FF25","#DDFF21","#E1FF1D","#E5FF19","#E9FF15","#EDFF11","#F1FF0D","#F5FF09","#F9FF05","#FDFF01","#FFFC00","#FFF800","#FFF400","#FFF000","#FFEC00","#FFE800","#FFE400","#FFE000","#FFDC00","#FFD800","#FFD400","#FFD000","#FFCC00","#FFC800","#FFC400","#FFC000","#FFBC00","#FFB800","#FFB400","#FFB000","#FFAC00","#FFA800","#FFA400","#FFA000","#FF9C00","#FF9800","#FF9400","#FF9000","#FF8C00","#FF8800","#FF8400","#FF8000","#FF7C00","#FF7800","#FF7400","#FF7000","#FF6C00","#FF6800","#FF6400","#FF6000","#FF5C00","#FF5800","#FF5400","#FF5000","#FF4C00","#FF4800","#FF4400","#FF4000","#FF3C00","#FF3800","#FF3400","#FF3000","#FF2C00","#FF2800","#FF2400","#FF2000","#FF1C00","#FF1800","#FF1400","#FF1000","#FF0C00","#FF0800","#FF0400","#FF0000","#FB0000","#F70000","#F30000","#EF0000","#EB0000","#E70000","#E30000","#DF0000","#DB0000","#D70000","#D30000","#CF0000","#CB0000","#C70000","#C30000","#BF0000","#BB0000","#B70000","#B30000","#AF0000","#AB0000","#A70000","#A30000","#9F0000","#9B0000","#970000","#930000","#8F0000","#8B0000","#870000","#830000","#7F0000")
clr_map <- colorRampPalette(clr_vector, bias = 3)(100)

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

# Initial values check for global max min
  # Forecasts
tmp.array <- ncvar_get(ncin,"q_ensemble_median") # dimensions (row=lon,col=lat,time) 
fMax <- max(tmp.array[,,], na.rm = TRUE)
fMin <- min(tmp.array[,,], na.rm = TRUE)
  # Baseline
bName = paste( iopath_parent, Domains[1], "/hist/raster/", DomainIds[1], 
               "_hist_raster_hydrol_monthly_q_ufz_mhm_v1.0_e1_", TrackingMonth, ".nc", sep="")
ncin <- nc_open(bName)
tmp.array <- ncvar_get(ncin,"q") # dimensions (row=lon,col=lat,time) 
bMax <- max(tmp.array[,], na.rm = TRUE)
bMin <- min(tmp.array[,], na.rm = TRUE)
  # Global max-min
gMax <- max(fMax, bMax, na.rm = TRUE)
gMin <- min(fMin, bMin, na.rm = TRUE)


# ### GIF generation
# # -----------------------
#   # make sure ImageMagick has been installed in your system
#   saveGIF({
    
    #### PDF generation
    # -----------------------
    pdf( paste(iopath_parent, "q_median_multiplot.pdf", sep = ""), width = 16, height = 6)  # Uncomment for pdf generation
    
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
                         "_hist_raster_hydrol_monthly_q_ufz_mhm_v1.0_e1_", TrackingMonth, ".nc", sep="")
          
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
          tmp.array <- ncvar_get(ncin,"q") # dimensions (row=lon,col=lat,time) 
          
          # Setup plot environment
          grid <- expand.grid(lon=lon, lat=lat)
          cutpts <- seq(gMin, gMax, length.out=120)
          x.scale <- list(at=seq(floor(min(lon)),ceiling(max(lon)),1))
          y.scale <- list(at=seq(floor(min(lat)),ceiling(max(lat)),1))
          
          # Setup plot data and plot
          tmp.slice <- tmp.array[,ncol(tmp.array):1] # flipping the latitude values as "lat" was flipped
          
          # Plot baseline
          myplot <- levelplot(tmp.slice ~ lon * lat, data=grid, aspect = "iso", pretty=T, at=cutpts,
                              col.regions=clr_map, xlab = "", ylab = "",
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
        fName = paste( iopath_parent, Domains[iDomain], "/frcst/raster/hydrol/", DomainIds[iDomain], 
                       "_frcst_raster_hydrol_monthly_q_ufz_mhm_v1.0_e1_", IssueMonth[iIssueMonth], ".nc", sep="")
        
        
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
        # tmp.array <- ncvar_get(ncin,"q_above_normal_probab") # dimensions (row=lon,col=lat,time) 
        tmp.array <- ncvar_get(ncin,"q_ensemble_median") # dimensions (row=lon,col=lat,time) 
        
        
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
                              col.regions=clr_map, xlab = "", ylab = "",
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
  # }, movie.name = paste(iopath_parent, "q_median_multiplot.gif", sep = ""),
  # interval = 2, nmax = 50, ani.width = 1400, ani.height = 400)


dev.off() # Uncomment for pdf generation

