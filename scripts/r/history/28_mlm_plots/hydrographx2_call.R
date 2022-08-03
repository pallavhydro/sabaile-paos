######################################################################################################### 
##
## ========================== Hydrograph call script
##
#########################################################################################################


# Source taylor-made functions
source("hydrographx2.R")


file1 <- "./discharge.nc"
file2 <- "./discharge2.nc"
opath <- "." # output path

suffix1 <- "def"
suffix2 <- "cal"

station_name <- "station_name"
station_id <- "9999999"


## Generate texts
title_text <- paste("Gauge: ", station_name, " . ", station_id) # Plot title


plot_hydrographx2(opath, file1, file2, suffix1, suffix2, station_id, title_text )

