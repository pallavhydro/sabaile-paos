#####################################################################################
##                   -------------------------------------------
## ================== Animator for mHM output netCDF files v1  =====================
##                   -------------------------------------------
##   
##  Code developer:    Pallav Kumar Shrestha    (pallav-kumar.shrestha@ufz.de)
##                     10 May 2019
##
##
##  Usage: 
##        
##        Rscript animate1.R
##
##        Output - makes a multi-plot of all variables in mHM and mRM flux states files
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
library(gridExtra)  # for using "grid.arrange" function
library(grid)




# Files
fName = c("mRM_Fluxes_States.nc", "mHM_Fluxes_States.nc" )
nfiles = 2

# Color map | color distribution | color ramp flip

var_names <-     c("interception",  "snowpack",      "SWC_L",         "SM_L",          "SM_Lall",       
                   "sealedSTW",     "unsatSTW",      "satSTW",        "PET",           "aET",           
                   "Q",             "QD",            "QIf",           "QIs",           "QB",            
                   "recharge",      "soil_infil_L",  "aET_L",         "preEffect",     "Qrouted")

clr_names <-     c("RdYlGn",        "Greys" ,        "BrBG",          "BrBG",          "BrBG",
                   "Blues",         "Blues",         "Blues",         "RdYlGn",        "RdYlGn",
                   "RdYlBu",        "RdYlBu",        "RdYlBu",        "RdYlBu",        "RdYlBu",
                   "YlOrBr",        "YlOrBr",        "RdYlGn",        "Blues",         "RdYlBu")

clr_cut_names <- c("lin",           "lin",           "lin",           "lin",           "lin",
                   "lin",           "lin",           "lin",           "lin",           "lin",
                   "low",           "low",           "low",           "low",           "low",
                   "lin",           "lin",           "lin",           "low",           "low")

clr_dir_names <- c("yes",           "yes",           "no",            "no",            "no",
                   "no",            "no",            "no",            "yes",           "yes",
                   "yes",           "yes",           "yes",           "yes",           "yes",
                   "no",            "no",            "yes",           "no",            "yes")



# Command line arguments
args <- commandArgs(trailingOnly = TRUE)
nvar_in <- as.numeric(args[1]) # number of variables to be included
var_names_in <- vector()
for (i in 1:nvar_in) { # loop over to enter the variables
  var_names_in[i] <- as.character(args[i+1])
  if (length(which(var_names == var_names_in[i])) == 0){
    print(paste("The variable name",var_names_in[i],"is not found!",sep = " "))
    q()
  }
}


#### Check and Open the netCDF files
if (!file.exists(fName[1])) {
  nfiles <- nfiles - 1
  print("Warning: mRM output file is missing")
} else {
  ncin_mrm <- nc_open(fName[1])
  ncin_common <- ncin_mrm
}
if (!file.exists(fName[2])) {
  nfiles <- nfiles - 1
  print("Warning: mHM output file is missing")
} else {
  ncin_mhm <- nc_open(fName[2])
  ncin_common <- ncin_mhm
}
if (nfiles == 0) {
  print("Error : both output files are missing. Nothing to plot!")
  q() # quit the program!
}


### Pre-read netCDF file for setup

# # get GLOBAL attributes
# title <- ncatt_get(ncin_mhm,0,"title") 
# title <- strwrap(title$value, width = 50)

# Read time attribute
nctime <- ncvar_get(ncin_common,"time")
tunits <- ncatt_get(ncin_common,"time","units") 
nt <- dim(nctime)
# Extract the time origin info
tustr <- strsplit(tunits$value, " ")
tdstr <- strsplit(unlist(tustr)[3], "-")
tmonth <- as.integer(unlist(tdstr)[2])
tday <- as.integer(unlist(tdstr)[3])
tyear <- as.integer(unlist(tdstr)[1])
tfinal <- chron(nctime/24, origin=c(tmonth, tday, tyear)) # nctime (hours) is converted to days
# Check the time resolution for GIF speed
temp_res_check <- tfinal[2] - tfinal[1]
if (temp_res_check <= 1) {
  gifinterval <- 0.2
} else if (temp_res_check >= 32) {
  gifinterval <- 2
} else {
  gifinterval <- 1
}

# Lat Lon suitable intervals
latlon_cutpts <- c(0.1, 0.2, 0.25, 0.5, 1, 2, 5)



#------------------------
#### ANIMATE! ####
#------------------------

animate <- function() {
  
  # Progress Bar
  pb=txtProgressBar(min=1, max=nt, style = 3)
  
  # Initialize
  p <- list() # Defining p as list

  for (itime in 1:nt) { # time loop

    for (ifile in 1:nfiles) { # file loop 
      
      if (nfiles == 2) { # both files available
        if (ifile == 1) {
          ncin <- ncin_mrm
        } else {
          ncin <- ncin_mhm
        }
      } else { # 1/2 files available
        if (exists("ncin_mrm")) {
          ncin <- ncin_mrm
        } else {
          ncin <- ncin_mhm
        }
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
      tfinal <- chron(nctime/24, origin=c(tmonth, tday, tyear)) # nctime (hours) is converted to days
      
      # Temporal data resolution for date ribbon
      temp_res_check <- tfinal[2] - tfinal[1]
      if (temp_res_check <= 1) {
        date_ribbon <- paste(days(tfinal[itime]), months(tfinal[itime]), years(tfinal[itime]), sep=" ") # date ribbon for daily data
      } else if (temp_res_check >= 32) {
        date_ribbon <- paste(years(tfinal[itime]),sep = " ") # date ribbon for yearly data
      } else {
        date_ribbon <- paste(months(tfinal[itime]), years(tfinal[itime]), sep=" ") # date ribbon for monthly data
      }
      
      # get LAT LON
      lon <- ncvar_get(ncin,"lon") 
      lon <- lon[,1] # we just need a vector of values in the direction in which lon changes
      nlon <- length(lon)
      lat <- ncvar_get(ncin,"lat") 
      lat <- lat[1,] # we just need a vector of values in the direction in which lat changes
      nlat <- length(lat) 
      
      lat <- rev(lat) # latitude flipping needed for mHM output netCDFs!
      
      # check for Western hemisphere
      if (lon[1] > tail(lon, n=1)) {
        lon <- rev(lon)
      }
      
      # # list all mHM variables
      # varlist <- names(ncin$var)
      # varlist <- varlist[ varlist != "time_bnds" & varlist !="lat" & varlist != "lon"] # excluding time and lat lon variables
      # nvar <- nvar + length(varlist)
      
      
      for (ivar in 1:nvar_in) { # variable loop
        
        # get VARIABLE and its attributes 
        tmp.array <- ncvar_get(ncin,var_names_in[ivar]) # dimensions (row=lon,col=lat,time) 
        dunits<- ncatt_get(ncin,var_names_in[ivar],"unit") 
        
        # get suitable color map attributes
        idx <- which(var_names == gsub("[!^0-9\\.]", "", var_names_in[ivar]))
        clr_cut <- clr_cut_names[idx]
        clr_dir <- clr_dir_names[idx]
        
        # Prepare grid, color and date
        grid <- expand.grid(lon=lon, lat=lat)
        val <- min(max(lon) - min(lon), max(lon) - min(lon))/2 # Value of suitable interval 
                                                               # (at least 3 cutpoints) along 
                                                               # shorter domain direction
        latlon_interval <- latlon_cutpts[which.min(abs(latlon_cutpts - val))]
        x.scale <- list(at=seq(floor(min(lon)),ceiling(max(lon)),latlon_interval))
        y.scale <- list(at=seq(floor(min(lat)),ceiling(max(lat)),latlon_interval))
        
        flr <- floor(min(tmp.array[,,], na.rm = TRUE))
        cel <- ceiling(max(tmp.array[,,], na.rm = TRUE))
          
          # color cut points 
        if (clr_cut == "low") {
          clr_cutpts <- 1 - log(seq(1, 10))/log(10) # low
        } else if (clr_cut == "high") {
          clr_cutpts <- log(seq(1, 10))/log(10) # high
        } else {
          clr_cutpts <- seq(1, 10)/10 # linear
        }
        clr_cutpts <- flr + clr_cutpts*(cel-flr)
        
          # color direction
        if (clr_dir == "yes") {
          color_direction = rev(brewer.pal(9, clr_names[idx])) # reversed
        } else {
          color_direction = brewer.pal(9, clr_names[idx]) # normal
        }
        
        tmp.slice <- tmp.array[, , itime]
        tmp.slice <- tmp.slice[,ncol(tmp.slice):1] # flipping the latitude values as "lat" was flipped
        myplot <- levelplot(tmp.slice ~ lon * lat, data=grid, aspect = "iso", pretty=T, at=clr_cutpts,
                              col.regions=color_direction, xlab = "", ylab = "",
                              main = paste(var_names_in[ivar]," (",dunits$value,")",sep=""), 
                              colorkey = list(tick.number=5),
                              scales=list(x=x.scale, tck=c(-1,-1), y=y.scale))

        
        # Save plot as an element of multiplot
        xplot = gridExtra:::latticeGrob(myplot)
        p[[ivar + (ifile-1) ]] <- xplot # p[[1]] is dedicated to the empty plot
        
        # Progress bar update
        setTxtProgressBar(pb, itime)
        
      }
    }
          
    # Determine the layout of multiplot
    cols <- ceiling(sqrt(nvar_in))
    rows <- floor(sqrt(nvar_in)) + as.integer( nvar_in/ 
              ( ceiling(sqrt(nvar_in))*floor(sqrt(nvar_in)) + 1) )
    count_empty_plots <- cols * rows - nvar_in    # number of empty plot to pad to the layout
    
    if (count_empty_plots != 0){
      xlay <- matrix(c(seq(1,length(p)),replicate(count_empty_plots,NA)), nrow = rows, ncol = cols, byrow = TRUE)
    } else { # 'replicate' creates problem when count_empty_plots = 0
      xlay <- matrix(c(seq(1,length(p))), nrow = rows, ncol = cols, byrow = TRUE)
    }
    
    select_grobs <- function(lay) {
      id <- unique(c(t(lay))) 
      id[!is.na(id)]
    }
    
    mymultiplot <- grid.arrange(grobs=p[select_grobs(xlay)], layout_matrix=xlay, 
                                top = textGrob(paste("\n", date_ribbon,"\n", sep=" "),
                                               gp=gpar(fontsize=20,font="Helvetica", just="left")))
  
  } 
  close(pb)
}


#### PDF generation
#-----------------------
pdf( paste("animate.pdf", sep=""), width = 12, height = 8)
animate()



#### GIF generation
#-----------------------

## ! NOTE: make sure ImageMagick has been installed in your system
saveGIF({  
  animate()
}, movie.name = paste("animate.gif", sep=""), interval=gifinterval, nmax = 500, ani.width = 1000, ani.height = 750)


