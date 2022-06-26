######################################################################################################### 
##
## ========================== Hydrograph call script
##
#########################################################################################################


# Source taylor-made functions
source("hydrographx2.R")


path1 <- "."
path2 <- "."

suffix1 <- "def"
suffix2 <- "cal"

station_name <- "station_name"
station_id <- "9999999"


## Generate texts
title_text <- paste("Gauge: ", station_name, " . ", station_id) # Plot title


plot_hydrographx2(path1, path2, suffix1, suffix2, station_id, title_text )

