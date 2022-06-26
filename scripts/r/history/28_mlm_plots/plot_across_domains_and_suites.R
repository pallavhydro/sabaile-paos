#####################################################################################
##                   ----------------------------------------------------------------
## ==================== Plots across domains across suites
##                   ----------------------------------------------------------------
## --- Code developer: 
## ------------------  Pallav Kumar Shrestha pallav-kumar.shrestha@ufz.de ------
## ------------------  09 Mar 2022 ---------------------------------------------
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
source("boxplot.R")
# source("timeseries_line.R")

plot_across_domains_and_suites <- function(path, path_suffix, file_suffix, title_text, caption_text ){
 

  # Paths
  # lut_file= "/home/shresthp/projects/gitlab/ecfpy/suites/mlm_2021/atable_mlm_global_dam_selection_v1_tm_adj_v3.csv"
  lut_file= "/Users/shresthp/tmp/Win7/global_mlm/selection/atable_mlm_global_dam_selection_v1_tm_adj_v3.csv"
  fNamein_scc_mlm_fluxesstates = "mLM_Fluxes_States.nc"

  # Suites
  suite_name    <- "mlm_2022_v9_reservoirs_as_lakes"
  suites_suffix <- c("evap7", "evap7_lamda_var", "evap7_psychro_var", "evap7_lamda_psychro_var", "evap7_albedo_const")
  nsuites       <- length(suites_suffix)

  # ====================== DATA

  # Read LUT file
  lut_data <- read.delim(lut_file, sep = "," , header = TRUE )
  ndomains = length(lut_data$station_id)
  # ndomains = 10

  # initialize (2D)
  var_matrix <- data.frame(matrix(data = NA, nrow = ndomains, ncol = nsuites))


  # Read simulated variables

  for (isuite in 1: nsuites){ # Suite loop


    # (Re-)initialze (1D)
    var_matrix_annual_sub   <- data.frame()
    var_matrix_monthly_sub  <- data.frame()
    var_matrix_monthly_index_sub  <- data.frame()
    var_matrix_daily_sub    <- data.frame()


    for (idomain in 1: ndomains){ # Dam loop
    
      domainid = lut_data$station_id[idomain]


      # == SIMULATIONS

      mlm_nc_file = paste(path, paste(suite_name, suites_suffix[isuite], sep = "_"), "work/mhm", domainid, path_suffix, 
                    fNamein_scc_mlm_fluxesstates , sep = "/")
      
      print(mlm_nc_file)

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
        tfinal  <- as.Date(chron(nctime/24, origin=c(tmonth, tday, tyear))) # nctime (days)

        # convert to xts
        lake_evap_xts       <- xts(as.numeric(lake_evap),   order.by = tfinal) # xts/ time series object created

        # convert to monthly and yearly
        lake_evap_annual    <- as.matrix(daily2annual (lake_evap_xts,  FUN = sum, na.rm = TRUE))
        lake_evap_monthly   <- as.matrix(daily2monthly(lake_evap_xts,  FUN = sum, na.rm = TRUE))
        lake_evap_monthly_index   <- as.matrix(.indexmon(as.xts(daily2monthly(lake_evap_xts,  FUN = sum, na.rm = TRUE))) + 1) # as month index starts from 0 for Jan
        lake_evap_daily     <- as.matrix(lake_evap_xts)
        
        # Pool values altogether at yearly, mothly and daily scales
        var_matrix_annual_sub <- rbind(var_matrix_annual_sub,   lake_evap_annual)
        var_matrix_monthly_sub<- rbind(var_matrix_monthly_sub,  lake_evap_monthly)
        var_matrix_monthly_index_sub<- rbind(var_matrix_monthly_index_sub,  lake_evap_monthly_index)
        var_matrix_daily_sub  <- rbind(var_matrix_daily_sub,    lake_evap_daily)

        # get annual mean
        lake_evap_annual_mean <- mean(lake_evap_annual,   na.rm = TRUE)

        # Store average annual values
        var_matrix[idomain, isuite] <- lake_evap_annual_mean
        
      }

      print(paste(idomain, domainid, sep = " "))

    } # Domain loop

    if (isuite == 1){ 
        # Initialize
        var_matrix_annual   <- var_matrix_annual_sub
        var_matrix_monthly  <- var_matrix_monthly_sub
        var_matrix_monthly_index  <- var_matrix_monthly_index_sub
        var_matrix_daily    <- var_matrix_daily_sub
      } else {
        # Column bind the yearly pool
        var_matrix_annual   <- cbind(var_matrix_annual,   var_matrix_annual_sub)
        var_matrix_monthly  <- cbind(var_matrix_monthly,  var_matrix_monthly_sub)
        var_matrix_monthly_index  <- cbind(var_matrix_monthly_index,  var_matrix_monthly_index_sub)
        var_matrix_daily    <- cbind(var_matrix_daily,    var_matrix_daily_sub)
      }

  } # Suite loop

  

  # == Average Annual values

  # add colnames
  colnames(var_matrix) <- suites_suffix

  # Yearly dE on average
  var_matrix_annual_deltas_average <- data.frame(name = lut_data$DAM_NAME[1:ndomains], 
                           deltaE_lamda         = var_matrix[,2] - var_matrix[,1],
                           deltaE_psychro       = var_matrix[,3] - var_matrix[,1],
                           deltaE_lamda_psychro = var_matrix[,4] - var_matrix[,1],
                           deltaE_albedo_constant = var_matrix[,5] - var_matrix[,1])

  # Reverse Sort according to alphabetical order so that A is at top and B is at bottom of the graph
  var_matrix_annual_deltas_average$name <- factor(var_matrix$name,levels = rev(sort(lut_data$DAM_NAME[1:ndomains])))

  # print(var_matrix$name)


  # == Annual values

  # Data frame of pool of yearly values
  var_matrix_annual_deltas  <- data.frame(deltaE_lamda         = var_matrix_annual[,2] - var_matrix_annual[,1], 
                                   deltaE_psychro       = var_matrix_annual[,3] - var_matrix_annual[,1],
                                   deltaE_lamda_psychro = var_matrix_annual[,4] - var_matrix_annual[,1])
  # == Monthly values

  # Monthly dE
  var_matrix_monthly_deltas <- data.frame(month                = var_matrix_monthly_index[,1],
                                   deltaE_lamda         = var_matrix_monthly[,2] - var_matrix_monthly[,1], 
                                   deltaE_psychro       = var_matrix_monthly[,3] - var_matrix_monthly[,1],
                                   deltaE_lamda_psychro = var_matrix_monthly[,4] - var_matrix_monthly[,1],
                                   deltaE_albedo_constant= var_matrix_monthly[,5] - var_matrix_monthly[,1])
  # == Daily values

  # Daily dE
  var_matrix_daily_deltas<- data.frame( deltaE_lamda         = var_matrix_daily[,2] - var_matrix_daily[,1], 
                                        deltaE_psychro       = var_matrix_daily[,3] - var_matrix_daily[,1],
                                        deltaE_lamda_psychro = var_matrix_daily[,4] - var_matrix_daily[,1])

  # Daily E
  var_matrix_annual_deltas_melt   <- melt(var_matrix_annual_deltas)
  var_matrix_monthly_deltas_melt  <- melt(var_matrix_monthly_deltas, measure.vars = c("deltaE_lamda", "deltaE_psychro", "deltaE_lamda_psychro", "deltaE_albedo_constant"))
  # var_matrix_monthly_deltas_melt  <- melt(var_matrix_monthly_deltas[1:4], measure.vars = c("deltaE_lamda", "deltaE_psychro", "deltaE_lamda_psychro"))
  var_matrix_daily_deltas_melt    <- melt(var_matrix_daily_deltas)

  

  # Melt
  lake_evap_df <- data.frame(lake_evap_data)
  lake_evap_df$id <- rownames(lake_evap_df)
  lake_evap_melted <- melt(lake_evap_df, measure.vars=methods)
  lake_evap_melted$id <- rep(seq.Date(as.Date(tfinal[1]),as.Date(tail(tfinal, n = 1)), by= "days"), nmethods)
  # Method colors
  # colors_methods <- c("orange", "grey", "black", "red", "blue")
  colors_methods <- c("black", "red", "blue")
  # labels_methods <- c(paste("adjusted_HS \n(", ceiling(lake_evap_annual[1]), " mm)", sep = "") , 
  #                     paste("harbeck1962 \n(", ceiling(lake_evap_annual[2]), " mm)", sep = "") , 
  #                     paste("linacre1977 \n(", ceiling(lake_evap_annual[3]), " mm)", sep = "") , 
  #                     paste("linacre1992 \n(", ceiling(lake_evap_annual[4]), " mm)", sep = "") , 
  #                     paste("debruin1978 \n(", ceiling(lake_evap_annual[5]), " mm)", sep = "") )
  labels_methods <- c(paste("both constant \n(", ceiling(lake_evap_annual[1]), " mm)", sep = "") , 
                      paste("lamda varying \n(", ceiling(lake_evap_annual[2]), " mm)", sep = "") , 
                      paste("psychro varying \n(", ceiling(lake_evap_annual[3]), " mm)", sep = "") )


  # ====================== GRAPHS


    # ========================================
    # Variable Stats across dams (VSAD) plots
    # ========================================

    # Annual average lake evaporation deltas compared to baseline
    plot_metrics_across_domains(var_matrix_annual_deltas_average, path, paste("vsad_annual_average_deltaE_lamda_",          file_suffix, ".pdf", sep = ""), var_matrix_annual_deltas_average$name, var_matrix_annual_deltas_average$deltaE_lamda,          "Dam", bquote("E"[lambda] ~ "-" ~ "E [mm]"), c(-30, 30))
    plot_metrics_across_domains(var_matrix_annual_deltas_average, path, paste("vsad_annual_average_deltaE_psychro_",        file_suffix, ".pdf", sep = ""), var_matrix_annual_deltas_average$name, var_matrix_annual_deltas_average$deltaE_psychro,        "Dam", bquote("E"[gamma] ~ "-" ~ "E [mm]"), c(-30, 30))
    plot_metrics_across_domains(var_matrix_annual_deltas_average, path, paste("vsad_annual_average_deltaE_lamda_psychro_",  file_suffix, ".pdf", sep = ""), var_matrix_annual_deltas_average$name, var_matrix_annual_deltas_average$deltaE_lamda_psychro,  "Dam", bquote("E"[lambda ~ gamma] ~ "-" ~ "E [mm]"), c(-30, 30))
    plot_metrics_across_domains(var_matrix_annual_deltas_average, path, paste("vsad_annual_average_deltaE_albedo_constant_",file_suffix, ".pdf", sep = ""), var_matrix_annual_deltas_average$name, var_matrix_annual_deltas_average$deltaE_albedo_constant,"Dam", bquote("E"[alpha ~ const.] ~ "-" ~ "E [mm]"), c(NA, NA))
    


    # ========================================
    # Variable Stats across dams x time (VSADT) box plots
    # ========================================

    # lake evaporation deltas compared to baseline
    xlabels <- c(  bquote("E"[lambda] ~ "-" ~ "E [mm]"), 
                   bquote("E"[gamma] ~ "-" ~ "E [mm]"), 
                   bquote("E"[lambda ~ gamma] ~ "-" ~ "E [mm]"),
                   bquote("E"[alpha ~ const.] ~ "-" ~ "E [mm]"))
    groupcolors <- c("#ff0000", "#e31320", "#c02a48", "#8c4d84", "#005fb8", "#1079dc", "#1f93ff", 
                     "#1079dc", "#005fb8", "#8c4d84", "#c02a48", "#e31320", "#ff0000")

    plot_boxplot(var_matrix_annual_deltas_melt,   path, paste("boxplot_yearly_evapdeltas_deltaE",  file_suffix, ".pdf", sep = ""), var_matrix_annual_deltas_melt$variable,  c("deltaE_lamda", "deltaE_psychro", "deltaE_lamda_psychro", "deltaE_albedo_const"), "Experiment", bquote("Yearly" ~ Delta ~"E" ~ "[mm]"),  xlabels, c(NA, NA))
    plot_boxplot(var_matrix_monthly_deltas_melt,  path, paste("boxplot_monthly_evapdeltas_deltaE", file_suffix, ".pdf", sep = ""), var_matrix_monthly_deltas_melt$variable, var_matrix_monthly_deltas_melt$month, groupcolors, month.abb, "Experiment", bquote("Monthly" ~ Delta ~"E" ~ "[mm]"), xlabels, c(-50, 50))


    # ========================================
    # Variable Time series across dams (VTAD) plots
    # ========================================

    # # lake albedo annual variation across domains
    # plot_timeseries_line(albedo_melted, path, paste("vtad_alb_", file_suffix, ".pdf", sep = ""), "Lake albedo seasonality across reservoirs", "lake albedo [-]", colors_latitude, "1 month", "%b", c(0, 0.6))
}
