#####################################################################################
##                   ----------------------------------------------------------------
## ==================== mHM simulation variables statistics plots
##                   ----------------------------------------------------------------
## --- Code developer: 
## ------------------  Pallav Kumar Shrestha pallav-kumar.shrestha@ufz.de ------
## ------------------  14 Feb 2022 ---------------------------------------------
##
## --- Mods: 
#####################################################################################


# Open libraries/ packages
library(ggplot2)
library(reshape) # for melt
library(ncdf4) 
library(chron)
library(xts) 
library(hydroTSM)
library(dplyr)
# Source taylor-made functions
source("timeseries_line.R")

plot_lake_evap <- function(path, path_suffix, file_suffix, title_text, caption_text ){
 

  # Paths
  # lut_file= "/home/shresthp/projects/gitlab/ecfpy/suites/mlm_2021/atable_mlm_global_dam_selection_v1_tm_adj_v3.csv"
  lut_file= "/Users/shresthp/tmp/Win7/global_mlm/selection/atable_mlm_global_dam_selection_v1_tm_adj_v3.csv"
  fNamein_scc_mlm_fluxesstates = "mLM_Fluxes_States.nc"


  # Methods
  # methods  <- c("evap1", "evap2", "evap3", "evap4", "evap6")
  methods  <- c("evap6", "evap7", "evap8")
  # methods  <- c("evap7", "evap7_lamda_var", "evap7_psychro_var")
  nmethods <- length(methods)

  # ====================== DATA

  # Read LUT file
  lut_data <- read.delim(lut_file, sep = "," , header = TRUE )
  ndomains = length(lut_data$station_id)
  # ndomains = 5

  # initialize (2D)
  var_matrix <- data.frame(matrix(data = NA, nrow = ndomains, ncol = 2))


  # Read simulated variables

  for (idomain in 1: ndomains){ # Dam loop
    
    domainid = lut_data$station_id[idomain]

    lake_evap_data  <- xts()

    for (iMethod in 1: nmethods){ # Method loop

      path_real <- paste(path, "./../../mlm_2022_v9_reservoirs_as_lakes_", methods[iMethod], "/work/mhm/", sep = "")


      mlm_nc_file = paste(path_real, domainid, path_suffix, fNamein_scc_mlm_fluxesstates , sep = "/")
      
      # check whether the netCDF file exists
      if (file.exists(mlm_nc_file)){
        
        # Read the netCDF file
        ncin <- nc_open(mlm_nc_file)
        # get VARIABLE
        lake_evap     <- ncvar_get(ncin,"Levap")  
        # Read time attribute
        nctime  <- ncvar_get(ncin,"time")
        tunits  <- ncatt_get(ncin,"time","units")
        nt      <- dim(nctime)
        # Close file
        nc_close(ncin)

        # Prepare the time origin
        tustr   <- strsplit(tunits$value, " ")
        tdstr   <- strsplit(unlist(tustr)[3], "-")
        tmonth  <- as.integer(unlist(tdstr)[2])
        tday    <- as.integer(unlist(tdstr)[3])
        tyear   <- as.integer(unlist(tdstr)[1])
        tchron <- chron(dates. = (nctime - 23)/24, origin=c(tmonth, tday, tyear)) # nctime (hours)
        tfinal <- as.POSIXct(tchron, tz = "GMT", origin=paste(tyear,tmonth,tday, sep = "-")) # nctime (hours)
        
        # convert to xts
        lake_evap_xts           <- xts(as.numeric(lake_evap),   order.by = tfinal) # xts/ time series object created
        colnames(lake_evap_xts) <- methods[iMethod]
        lake_evap_data          <- cbind(lake_evap_data, lake_evap_xts)
        
      } else {
        
        lake_evap_xts           <- xts(as.numeric(rep(NA, length(tfinal))),   order.by = tfinal) # xts/ time series object created
        colnames(lake_evap_xts) <- methods[iMethod]
        lake_evap_data          <- cbind(lake_evap_data, lake_evap_xts)
        
      }

    } # Method loop


    # == Time series per domain

    # Annual average value
      # convert to yearly
      lake_evap_annual    <- as.matrix(daily2annual(lake_evap_data,  FUN = sum, na.rm = TRUE))
      lake_evap_annual    <- apply(lake_evap_annual, 2, FUN = mean, na.rm = TRUE)

    # Melt daily
    lake_evap_df <- data.frame(lake_evap_data)
    lake_evap_df$id <- rownames(lake_evap_df)
    lake_evap_melted <- melt(lake_evap_df, measure.vars=methods)
    lake_evap_melted$id <- rep(seq.Date(as.Date(tfinal[1]),as.Date(tail(tfinal, n = 1)), by= "days"), nmethods)
    
    # Melt monthly
    lake_evap_monthly <- as.xts(daily2monthly(lake_evap_data,  FUN = sum, na.rm = TRUE))
    lake_evap_monthly_df <- data.frame(lake_evap_monthly)
    lake_evap_monthly_df$id <- rownames(lake_evap_monthly_df)
    lake_evap_monthly_melted <- melt(lake_evap_monthly_df, measure.vars=methods)
    lake_evap_monthly_melted$id <- rep(seq.Date(as.Date(tfinal[1]),as.Date(tail(tfinal, n = 1)), by= "months"), nmethods)
    
    # Method colors
    # colors_methods <- c("orange", "grey", "black", "red", "blue")
    colors_methods <- c("black", "red", "blue")
    # labels_methods <- c(paste("adjusted_HS \n(", ceiling(lake_evap_annual[1]), " mm)", sep = "") ,
    #                     paste("harbeck1962 \n(", ceiling(lake_evap_annual[2]), " mm)", sep = "") ,
    #                     paste("linacre1977 \n(", ceiling(lake_evap_annual[3]), " mm)", sep = "") ,
    #                     paste("linacre1992 \n(", ceiling(lake_evap_annual[4]), " mm)", sep = "") ,
                        
    labels_methods <- c(paste("debruin1978 \n(", ceiling(lake_evap_annual[1]), " mm)", sep = "") ,
                        paste("penman1952 \n(", ceiling(lake_evap_annual[2]), " mm)", sep = "") ,
                        paste("priestleytaylor1972 \n(", ceiling(lake_evap_annual[3]), " mm)", sep = "") )
    
    # labels_methods <- c(paste("both constant \n(", ceiling(lake_evap_annual[1]), " mm)", sep = "") , 
    #                     paste("lamda varying \n(", ceiling(lake_evap_annual[2]), " mm)", sep = "") , 
    #                     paste("psychro varying \n(", ceiling(lake_evap_annual[3]), " mm)", sep = "") )


    # ====================== GRAPHS

     
      # ========================================
      # Time series across methods (TAM) plots
      # ========================================

      title_text <- paste("dam: ", lut_data$DAM_NAME[idomain], " (", lut_data$COUNTRY[idomain], ")", "    .    gauge:", lut_data$station_id[idomain], "    .    period: calibration" )

      # lake evap time series across methods
      # Daily
      plot_timeseries_line(lake_evap_melted, paste(path, domainid, path_suffix, sep = "/"), 
                            paste("tam_levap_daily_6_7_8.pdf", sep = ""), title_text, 
                            "daily lake evaporation [mm]", colors_methods, 0.5, labels_methods, "top", "1 year", "%Y", c(0, NA))
      # Monthly
      plot_timeseries_line(lake_evap_monthly_melted, paste(path, domainid, path_suffix, sep = "/"), 
                           paste("tam_levap_monthly_6_7_8.pdf", sep = ""), title_text, 
                           "monthly lake evaporation [mm]", colors_methods, 1, labels_methods, "top", "1 year", "%Y", c(0, NA))
      

      print(paste(idomain, domainid, sep = " "))

  } # Dam loop

  

}
