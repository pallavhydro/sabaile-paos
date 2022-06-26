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
library(viridis)
library(RColorBrewer)
# Source taylor-made functions
source("metrics_across_domains.R")
source("timeseries_line.R")

plot_across_domains <- function(path, path_suffix, file_suffix, title_text, caption_text ){
 

  # Paths
  # lut_file= "/home/shresthp/projects/gitlab/ecfpy/suites/mlm_2021/atable_mlm_global_dam_selection_v1_tm_adj_v3.csv"
  lut_file= "/Users/shresthp/tmp/Win7/global_mlm/selection/atable_mlm_global_dam_selection_v1_tm_adj_v3.csv"
  fNamein_scc_mlm_fluxesstates = "mLM_Fluxes_States.nc"
  fNamein_albedo = "fort.99"



  # ====================== DATA

  # Read LUT file
  lut_data <- read.delim(lut_file, sep = "," , header = TRUE )
  ndomains = length(lut_data$station_id)

  # initialize (2D)
  var_matrix <- data.frame(matrix(data = NA, nrow = ndomains, ncol = 2))

  # Initialize Albedo data 
  tchron <- as.POSIXct(chron(dates. = seq(0,364), origin=c(1, 1, 2001)), "GMT", origin=paste(2001,1,1, sep = "-"))
  albedo_data <- xts(order.by = tchron) # empty xts with only time index
  # latitude <- xts(lut_data$Latitude, order.by = tchron)


  # Read simulated variables

  for (idomain in 1: ndomains){ # Dam loop
    
    domainid = lut_data$station_id[idomain]


    # == Dam CHARACTERISTICS

    # Store dam characteristics
    var_matrix[idomain, 1] <- lut_data$Latitude[idomain]
    var_matrix[idomain, 2] <- lut_data$ELEV_MASL[idomain]


    # # == ALBEDO

    # # Read Albedo seasonality file (its in main folder ie "output/cal" needs to be eliminated)
    # alb_file = paste(path, domainid, substring(path_suffix, 1, nchar(path_suffix)-10), fNamein_albedo , sep = "/")
    # alb_data <- read.delim(alb_file, sep = "" , header = FALSE )

    # # get annual mean
    # lake_albedo_annual  <- mean(as.numeric(alb_data[,2]),   na.rm = TRUE)
    # var_matrix[idomain, 6] <- lake_albedo_annual

    # # store annual seasonality
    # albedo_ts <- xts(as.numeric(alb_data[,2]), order.by = tchron)
    # colnames(albedo_ts) <- paste("D",lut_data$GRAND_ID[idomain], sep = "")
    # albedo_data <- cbind(albedo_data, albedo_ts)


    # == CLIMATOLOGY

    mlm_nc_file = paste(path, domainid, path_suffix, fNamein_scc_mlm_fluxesstates , sep = "/")
    
    # check whether the neCDF file exists
    if (file.exists(mlm_nc_file)){
      
      # Read the netCDF file
      ncin <- nc_open(mlm_nc_file)
      # get VARIABLE
      lake_evap     <- ncvar_get(ncin,"Levap")  
      lake_pre      <- ncvar_get(ncin,"Lpre")   
      lake_percol   <- ncvar_get(ncin,"Lpercol")  
      lake_evap_rn  <- ncvar_get(ncin,"Levap_Rn")  
      lake_evap_ah  <- ncvar_get(ncin,"Levap_Ah")  
      lake_evap_vpd <- ncvar_get(ncin,"Levap_Vpd")  
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
      tfinal  <- as.Date(chron(nctime/24, origin=c(tmonth, tday, tyear))) # nctime (days)

      # convert to xts
      lake_evap_xts     <- xts(as.numeric(lake_evap),   order.by = tfinal) # xts/ time series object created
      lake_pre_xts      <- xts(as.numeric(lake_pre),    order.by = tfinal)
      lake_percol_xts   <- xts(as.numeric(lake_percol), order.by = tfinal)
      lake_evap_rn_xts     <- xts(as.numeric(lake_evap_rn),   order.by = tfinal) # xts/ time series object created
      lake_evap_ah_xts     <- xts(as.numeric(lake_evap_ah),   order.by = tfinal) # xts/ time series object created
      lake_evap_vpd_xts     <- xts(as.numeric(lake_evap_vpd),   order.by = tfinal) # xts/ time series object created

      # convert to yearly
      lake_evap_annual    <- as.matrix(daily2annual(lake_evap_xts,  FUN = sum, na.rm = FALSE))
      lake_pre_annual     <- as.matrix(daily2annual(lake_pre_xts,   FUN = sum, na.rm = FALSE))
      lake_percol_annual  <- as.matrix(daily2annual(lake_percol_xts,FUN = sum, na.rm = FALSE))
      lake_evap_rn_annual    <- as.matrix(daily2annual(lake_evap_rn_xts,  FUN = sum, na.rm = FALSE))
      lake_evap_ah_annual    <- as.matrix(daily2annual(lake_evap_ah_xts,  FUN = sum, na.rm = FALSE))
      lake_evap_vpd_annual   <- as.matrix(daily2annual(lake_evap_vpd_xts,  FUN = sum, na.rm = FALSE))

      # get annual mean
      lake_evap_annual    <- mean(lake_evap_annual,   na.rm = TRUE)
      lake_pre_annual     <- mean(lake_pre_annual,    na.rm = TRUE)
      lake_percol_annual  <- mean(lake_percol_annual, na.rm = TRUE)
      lake_evap_rn_annual    <- mean(lake_evap_rn_annual,   na.rm = TRUE)
      lake_evap_ah_annual    <- mean(lake_evap_ah_annual,   na.rm = TRUE)
      lake_evap_vpd_annual   <- mean(lake_evap_vpd_annual,   na.rm = TRUE)

      # Store annual mean values
      var_matrix[idomain, 3] <- lake_evap_annual
      var_matrix[idomain, 4] <- lake_pre_annual
      var_matrix[idomain, 5] <- lake_percol_annual
      var_matrix[idomain, 6] <- lake_evap_rn_annual
      var_matrix[idomain, 7] <- lake_evap_ah_annual
      var_matrix[idomain, 8] <- lake_evap_vpd_annual
      
    }
    print(paste(idomain, domainid, 
                round(lake_evap_rn_annual/lake_evap_annual * 100, 2), 
                round(lake_evap_ah_annual/lake_evap_annual * 100, 2), 
                round(lake_evap_vpd_annual/lake_evap_annual * 100, 2), 
                sep = " "))
  }

  # == 1 value per domain

  # add colnames
  colnames(var_matrix) <- c("lat", "elev", "evap","pre", "percol", "evap_rn", "evap_ah", "evap_vpd") #, "alb")

  # Conver to DF
  var_matrix <- data.frame(name = lut_data$DAM_NAME, 
                           lat    = var_matrix[,1], 
                           elev   = var_matrix[,2],
                           evap   = var_matrix[,3], 
                           pre    = var_matrix[,4], 
                           percol = var_matrix[,5], 
                           evap_rn= var_matrix[,6], 
                           evap_ah= var_matrix[,7], 
                           evap_vpd= var_matrix[,8]) 
                           # alb    = var_matrix[,6])



  # Reverse Sort according to alphabetical order so that A is at top and B is at bottom of the graph
  var_matrix$name <- factor(var_matrix$name,levels = rev(sort(lut_data$DAM_NAME[1:ndomains])))

  # Average stats
  print(paste(mean(var_matrix$evap), mean(var_matrix$evap_rn), mean(var_matrix$evap_ah), mean(var_matrix$evap_vpd), sep= " "))
  
  # == Time series per domain

  # # Melt
  # albedo_df <- data.frame(albedo_data)
  # albedo_df$id <- rownames(albedo_df)
  # albedo_melted <- melt(albedo_df, measure.vars=paste("D", lut_data$GRAND_ID[1:ndomains], sep = ""))
  # albedo_melted$id <- rep(seq.Date(as.Date(tchron[1]),as.Date(tail(tchron, n = 1)), by= "days"), ndomains)
  # # Domain colors
  # # colors_latitude <- colorspace::diverge_hsv(ndomains)
  # # colors_latitude <- colors_latitude[order(abs(lut_data$Latitude))]
  # colors_latitude <- rep("blue", ndomains)

  # Melt evaporation components
  evap_components_df <- data.frame(var_matrix$name, var_matrix$evap_rn, var_matrix$evap_ah, var_matrix$evap_vpd)
  colnames(evap_components_df) <- c("name", "evap_rn", "evap_ah", "evap_vpd")
  evap_components_melted <- melt(evap_components_df, measure.vars = c("evap_rn", "evap_ah", "evap_vpd"))
  

  # ====================== GRAPHS

    # ========================================
    # Characteristic Stats across dams (CSAD) plots
    # ========================================

    # lake latitude
    plot_metrics_across_domains(var_matrix, path, paste("csad_lat_", file_suffix, ".pdf", sep = ""), var_matrix$name, var_matrix$lat, "Dam", "lake latitude [deg]", c(NA, NA))
    # lake elevation
    plot_metrics_across_domains(var_matrix, path, paste("csad_elev_", file_suffix, ".pdf", sep = ""), var_matrix$name, var_matrix$elev, "Dam", "lake elevation [m a.s.l.]", c(0, NA))
    

    # ========================================
    # Variable Stats across dams (VSAD) plots
    # ========================================

    # # lake albedo (annual average)
    # plot_metrics_across_domains(var_matrix, path, paste("vsad_alb_", file_suffix, ".pdf", sep = ""), var_matrix$name, var_matrix$alb, "Dam", "lake albedo [-]", c(0, NA))
    # lake evaporation
    plot_metrics_across_domains(var_matrix, path, paste("vsad_evap_", file_suffix, ".pdf", sep = ""), var_matrix$name, var_matrix$evap, "Dam", "lake evaporation [mm.yr-1]", c(0, 3000))
    # # lake evaporation components (Penman)
    # plot_metrics_across_domains(evap_components_melted, path, paste("vsad_evap_components_", file_suffix, ".pdf", sep = ""), evap_components_melted$name, evap_components_melted$value, "Dam", "lake evaporation [mm.yr-1]", c(0, 3000))
    # lake precipitation
    plot_metrics_across_domains(var_matrix, path, paste("vsad_pre_", file_suffix, ".pdf", sep = ""), var_matrix$name, var_matrix$pre, "Dam", "lake precipitation [mm.yr-1]", c(0, NA))
    # percolation
    plot_metrics_across_domains(var_matrix, path, paste("vsad_percol_", file_suffix, ".pdf", sep = ""), var_matrix$name, var_matrix$percol, "Dam", "percolation [mm.yr-1]", c(0, NA))
    

    # ========================================
    # Variable Time series across dams (VTAD) plots
    # ========================================

    # # lake albedo annual variation across domains
    # plot_timeseries_line(albedo_melted, path, paste("vtad_alb_", file_suffix, ".pdf", sep = ""), "Lake albedo seasonality across reservoirs", "lake albedo [-]", colors_latitude, "1 month", "%b", c(0, 0.6))
}
