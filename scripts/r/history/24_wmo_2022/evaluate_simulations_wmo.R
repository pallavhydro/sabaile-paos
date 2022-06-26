######################################################################################################### 
##                            ---------------------------------------------------------------------------
## ========================== evaluate ulysses streamflow simulations (WMO 2022)
##                            ----------------------------------------------------------------------------
## ---------- Code developer: 
## -------------------------  Pallav Kumar Shrestha pallav-kumar.shrestha@ufz.de ------
## -------------------------  28 April 2022 ----------------------------------------
#########################################################################################################

#### Gives one set of skill scores for the whole simulation period


# Open libraries/ packages
library(ncdf4) 
library(chron)
library(xts) 
library(hydroGOF) # nse, kge
library(hydroTSM) # daily2monthly
library(ggplot2)
library(reshape) # for melt
library(dplyr)

# Source taylor-made functions
source("/Users/shresthp/git/GitLab/global_mlm/scripts/plots/metrics_cdf.R")


  
  # ========  CONTROL  =============================================


  # Parameters

  t_res       = "daily" # "monthly"
  dataset     = "wmo" # "wmo", "mhm_global", "ulysses_selected"
  obs_format  = 1
  
  path = "."
  output_folder     = "performance"
  grdc_folder       = "selected_GRDC_daily" # "/Users/shresthp/Nextcloud/Cloud/macbook/01_work/Projects/04_ULYSSES/07_skill_assessment/GRDC_time_series" #"selected_GRDC_daily"
  sim_folder_v2     = "q_09_05_2022_merge_format" 
  sim_folder_v1     = "q_27_04_2022_merge_format" 
  grdc_fname_suffix = "_Q_Day.Cmd.txt" #".day" #"_Q_Day.Cmd.txt"
  sim_fname_suffix  = "_wmo-basin-"
  neval_days_minimum= 365
  
  # LUT file & nodata
  if (dataset == "wmo"){
    flut      = "luts/wmo_gauges.txt"
    nodata_grdc = -999
  } else if (dataset == "mhm_global"){
    flut      = "luts/LUT_area_is_div_cosLAT__all_ulysses_MOVED_LATLON_unique_argentina_format.csv"
    nodata_grdc = -9999
  } else if (dataset == "ulysses_selected"){
    flut      = "luts/LUT_120steamflow_stations_18_01_21.txt"
    nodata_grdc = -9999
  }
  nodata_sim  = -999
  
  # eval_start = as.Date("1981-01-01", format = "%Y-%m-%d")
  # eval_end   = as.Date("1989-10-06", format = "%Y-%m-%d")
  
  # eval_start = as.Date("1989-10-07", format = "%Y-%m-%d")
  # eval_end   = as.Date("2021-12-31", format = "%Y-%m-%d")
  # 
  eval_start = as.Date("1991-01-01", format = "%Y-%m-%d")
  eval_end   = as.Date("2021-12-31", format = "%Y-%m-%d")
  
  hm         = c("JULES") #, "PGB", "mHM", "mHM")
  hm_colors  = c("red", "orange", "blue", "deepskyblue4" )
  hm_lines   = c(1, 1, 1, 1)
  
  
  
  
  # ========  CODE  =============================================
  
  
  # Read LUT file
  if (dataset == "wmo"){
    data_lut  <- read.delim(flut, sep = "\t")
    data_lut  <- data_lut[order(data_lut$WMO.Basin.Mo.),]
  } else if (dataset == "mhm_global" || dataset == "ulysses_selected"){
    data_lut  <- read.delim(flut, sep = ",")
  }
  data_lut_extra <- read.delim("luts/LUT_GRDC_ULYSSES120gauges.csv", sep = ",")
    
  # initialize (2D)
  nse_matrix <- data.frame(matrix(data = NA, nrow = length(data_lut[,1]), ncol = length(hm),
                                     dimnames = list(NULL, hm)))
  
     kge_matrix <- nse_matrix
       r_matrix <- nse_matrix
    beta_matrix <- nse_matrix
   alpha_matrix <- nse_matrix
    
   
   
   
  # Loop across hms
  for (ihm in seq(1, length(hm))){
  
    
    # select sim folder
    if (ihm == 3){
      sim_folder <- sim_folder_v1
    } else {
      sim_folder <- sim_folder_v2
    }
    
    # initialize (2D)
    output_matrix <- data.frame(matrix(data = NA, nrow = length(data_lut[,1]), ncol = 14,
                                       dimnames = list(NULL, c("sim_id", "GRDC_id", "grdc_exists",  
                                                               "grdc_nlines", "grdc_neval_days",
                                                               "grdc_start", "grdc_end", 
                                                               "sim_exists", "overlap_years",
                                                               "NSE", "KGE", "r", "beta", "alpha"))))
    # Loop across WMO basins
    for (igauge in seq(1, length(data_lut[,1]))){
      
      
      # Get IDs
      if (dataset == "wmo"){
        iwmo  <- data_lut$WMO.Basin.Mo.[igauge]
        igrdc <- data_lut$GRDC.No.[igauge]
      } else if (dataset == "mhm_global"){
        iwmo  <- data_lut$StationID[igauge]
      } else if (dataset == "ulysses_selected"){
        iwmo  <- data_lut$id[igauge]
        igrdc <- iwmo
      }
      
      # store
      output_matrix$sim_id[igauge]  <- iwmo
      output_matrix$GRDC_id[igauge] <- igrdc
      
      # Data files
      grdc_fname = paste(igrdc, grdc_fname_suffix, sep = "")
      sim_fname  = paste(hm[ihm], sim_fname_suffix, iwmo, ".csv", sep = "")
      
      # Check whether files exist
      exist_grdc <- file.exists(paste(grdc_folder, grdc_fname, sep = "/"))
      exist_sim  <- file.exists(paste(sim_folder, sim_fname, sep = "/"))
      
      # store
      output_matrix$grdc_exists[igauge] <- exist_grdc
      output_matrix$sim_exists[igauge]  <- exist_sim
      
      
      # Proceed if both files exist
      if (exist_grdc && exist_sim){
        
        
        # ========  READ  =============================================
        
        
        # Get the number of data lines in grdc file
        if (dataset == "wmo"){
          # from line 35
          nlines_grdc <- read.delim(paste(grdc_folder, grdc_fname, sep = "/"), header = FALSE, sep = ":", skip = 34, nrows = 1)[2]
        } else if (dataset == "mhm_global" || dataset == "ulysses_selected"){
          dummy <- read.delim(paste(grdc_folder, grdc_fname, sep = "/"), header = FALSE, sep = "")
          nlines_grdc <- length(dummy[,1]) - 5
        }
        
        
        
        # Store
        output_matrix$grdc_nlines[igauge] <- as.numeric(nlines_grdc)
        
        # Check whether there is any data in the GRDC file
        if (nlines_grdc > 0){
          
          # Read the files
          if (obs_format == 1){ # original GRDC
            
            data_grdc <- read.delim(paste(grdc_folder, grdc_fname, sep = "/"), header = FALSE, sep = ";", skip = 37)
            ncol_obs  <- 3
          
          } else if (obs_format == 2){ # mhm GRDC
            
            data_grdc <- read.delim(paste(grdc_folder, grdc_fname, sep = "/"), header = FALSE, sep = "", skip = 5)
            ncol_obs  <- 6
            dStart <- as.Date(paste(data_grdc[1,1],"-",data_grdc[1,2],"-",data_grdc[1,3],sep=""))  # Infering the start date
            nData <- length(data_grdc[,1])
            dEnd <- as.Date(paste(data_grdc[nData,1],"-",data_grdc[nData,2],"-",data_grdc[nData,3],sep=""))  # Infering the end date
            
          }
          data_sim  <- read.delim(paste(sim_folder, sim_fname, sep = "/"), header = TRUE, sep = ",")
          
          # ========  PROCESS  =============================================
          
          # Prepare dates
          if (obs_format == 1){ # original GRDC
            grdc_date  <- as.Date(data_grdc[,1])
          } else if (obs_format == 2){ # mhm GRDC
            grdc_date <- seq.Date(dStart,dEnd, by= "days")
          }
          sim_date   <- as.Date(data_sim[,1])
          
          # Store
          output_matrix$grdc_start[igauge] <- as.character(grdc_date[1])
          output_matrix$grdc_end[igauge]   <- as.character(grdc_date[as.numeric(nlines_grdc)])
          
          
          # Store data as XTS
          q_grdc     <- xts(as.numeric(data_grdc[,ncol_obs]),  order.by = grdc_date)
          q_sim      <- xts(as.numeric( data_sim[,2]),  order.by =  sim_date)
          
          # Identify NAs
          q_grdc[q_grdc == nodata_grdc] <- NA
          q_sim [ q_sim ==  nodata_sim] <- NA
          
          
          # ========  EVAL =============================================
          
          # Append grdc and sim
          q_all           <- cbind(q_sim, q_grdc)
          colnames(q_all) <- c("sim", "grdc")
          
          # Check whether gauge was missing in the global modelling extent
          if ( sum(q_all$sim > 0, na.rm = TRUE) != 0){
          
            # Subset for evaluation period
            q_eval     <- q_all[paste(eval_start, eval_end, sep = "/")] 
            
            # Store 
            output_matrix$overlap_years[igauge]  <- round(sum(!is.na(q_eval$grdc + q_eval$sim))/ 365, 1)
            output_matrix$grdc_neval_days[igauge]<- sum(!is.na(q_eval$grdc))
            
            # conver to monthly?
            if (t_res == "monthly"){
              q_eval <- daily2monthly(q_eval, FUN = mean, na.rm = TRUE)
            }
            
            
           
            if (length(q_eval) > 0 && sum(!is.na(q_eval$grdc)) >= neval_days_minimum){
              
              # Store performance metrics
              output_matrix$NSE[igauge]  <- NSE(as.numeric(q_eval$sim), as.numeric(q_eval$grdc), na.rm = TRUE)
              
              kge_store                  <- KGE(as.numeric(q_eval$sim), as.numeric(q_eval$grdc), na.rm = TRUE, out.type = "full")
              output_matrix$KGE[igauge]  <- kge_store$KGE.value # KGE
              output_matrix$r[igauge]    <- kge_store$KGE.elements[1] # r
              output_matrix$beta[igauge] <- kge_store$KGE.elements[2] # beta
              output_matrix$alpha[igauge]<- kge_store$KGE.elements[3] # alpha
              
              # # Store sim time series
              # if (!exists("q_sim_all")){
              #   q_sim_all <- q_eval$sim
              #   colnames(q_sim_all) <- paste("wmo_",iwmo, sep = "")
              # } else {
              #   q_sim_all <- cbind(q_sim_all, q_eval$sim)
              #   names(q_sim_all)[names(q_sim_all) == "sim"] <- paste("wmo_",iwmo, sep = "")
              # }
              # 
              # # Store obs time series
              # if (ihm == 1){
              #   if (!exists("q_obs_all")){
              #     q_obs_all <- q_eval$grdc
              #     colnames(q_obs_all) <- paste("wmo_",iwmo, sep = "")
              #   } else {
              #     q_obs_all <- cbind(q_obs_all, q_eval$grdc)
              #     names(q_obs_all)[names(q_obs_all) == "grdc"] <- paste("wmo_",iwmo, sep = "")
              #   } 
              # }
              
            }
            
          } # checking whether sim contains only 0s
          
        } # nlines in GRDC file check
        
      } # Files exist check
      
    } # WMO basins loop
    
    # ihm = 2
    
    nse_matrix[, ihm] <- output_matrix$NSE
    kge_matrix[, ihm] <- output_matrix$KGE
      r_matrix[, ihm] <- output_matrix$r
   beta_matrix[, ihm] <- output_matrix$beta
  alpha_matrix[, ihm] <- output_matrix$alpha
  
  # q_sim_all[is.na(q_sim_all)] <- -9999
  # write.zoo(q_sim_all, file = paste(path, "simulations_daily", paste("sims_1991_2019_daily_", hm[ihm], "_ulysses.txt", sep = ""), sep = "/"),
  #             quote = F, row.names = F, index.name = "Date")
  # rm("q_sim_all")
  # if (ihm == 1){
  #   q_obs_all[is.na(q_obs_all)] <- -9999
  #   write.zoo(q_obs_all, file = paste(path, "simulations_daily", "obs_1991_2019_daily_grdc.txt", sep = "/"),
  #               quote = F, row.names = F, index.name = "Date")
  #   rm("q_obs_all")
  # }
  
  
  print(paste(hm[ihm], "complete", sep = " "))
    
  } # hm loop
  
  count_valid_gauge <- sum(!is.na(output_matrix$NSE))
  title_text = paste("gauge count: ", count_valid_gauge, sep = "")
  
  # Filter analysis
  a <- output_matrix %>% filter(!sim_exists) # count of excluded due to area error
  a <- output_matrix %>% filter(sim_exists) %>% filter(!grdc_exists) # count of no grdc file
  a <- output_matrix %>% filter(sim_exists) %>% filter(grdc_exists) %>% filter(grdc_nlines == 0) # count of no data in the grdc file
  # a <- output_matrix %>% filter(sim_exists) %>% filter(grdc_exists) %>% filter(grdc_nlines != 0) %>% filter(overlap_years == 0) # count of no data after 1991
  a <- output_matrix %>% filter(sim_exists) %>% filter(grdc_exists) %>% filter(grdc_nlines != 0) %>% filter(grdc_neval_days < neval_days_minimum) # count of no data after 1991
  
  
  ### Add Olda's mHM metrics CDF
  # Read Olda's metrics
  data_lut_v2 <- read.delim("luts/LUT_WMO2022_v2_def.txt", sep = " ")
  data_lut_v2 <- data_lut_v2[order(data_lut_v2$ID),]
  data_lut_v2[data_lut_v2 == -9999] <- NA
  # Join table to output_matrix
  output_matrix_joined <- merge(output_matrix, data_lut_v2, by.x = "sim_id", by.y = "ID", all = TRUE)
  # Add Olda's metrics to metrics matrices
  nse_matrix_joined <- cbind(   nse_matrix, mHM_v2_def = output_matrix_joined$nse_day)
  kge_matrix_joined <- cbind(   kge_matrix, mHM_v2_def = output_matrix_joined$kge_day)
  r_matrix_joined <- cbind(     r_matrix, mHM_v2_def = output_matrix_joined$r_day)
  beta_matrix_joined <- cbind(  beta_matrix, mHM_v2_def = output_matrix_joined$beta_day)
  alpha_matrix_joined <- cbind( alpha_matrix, mHM_v2_def = output_matrix_joined$alpha_day)
  # Take common gauges only
   nse_matrix_common <-    nse_matrix_joined %>% filter(!is.na(mHM)) %>% filter(!is.na(mHM_v2_def))
   kge_matrix_common <-    kge_matrix_joined %>% filter(!is.na(mHM)) %>% filter(!is.na(mHM_v2_def))
     r_matrix_common <-      r_matrix_joined %>% filter(!is.na(mHM)) %>% filter(!is.na(mHM_v2_def))
  beta_matrix_common <-   beta_matrix_joined %>% filter(!is.na(mHM)) %>% filter(!is.na(mHM_v2_def))
 alpha_matrix_common <-  alpha_matrix_joined %>% filter(!is.na(mHM)) %>% filter(!is.na(mHM_v2_def))
  # Graph properties
  hm_colors <- c(hm_colors, "black")
  hm_lines  <- c(hm_lines, 1)
  hm         = c("JULES", "PGB", "mHM_uly_v1", "mHM_uly_v2", "mHM_global_v2_def")
  count_valid_gauge <- count(nse_matrix_joined %>% filter(!is.na(mHM)) %>% filter(!is.na(mHM_v2_def)))
  title_text = paste("gauge count: ", count_valid_gauge, sep = "")
  # Assemble table of metrics
  tab_metrics <- cbind(output_matrix_joined[,c(1,2,20:24)], 
                       nse_day_mhm =   round(nse_matrix$mHM, 4),
                       kge_day_mhm =   round(kge_matrix$mHM, 4),
                         r_day_mhm =     round(r_matrix$mHM, 4),
                      beta_day_mhm =  round(beta_matrix$mHM, 4),
                     alpha_day_mhm = round(alpha_matrix$mHM, 4),
                       nse_day_pgb =   round(nse_matrix$PGB, 4),
                       kge_day_pgb =   round(kge_matrix$PGB, 4),
                         r_day_pgb =     round(r_matrix$PGB, 4),
                      beta_day_pgb =  round(beta_matrix$PGB, 4),
                     alpha_day_pgb = round(alpha_matrix$PGB, 4),
                     nse_day_jules =   round(nse_matrix$JULES, 4),
                     kge_day_jules =   round(kge_matrix$JULES, 4),
                       r_day_jules =     round(r_matrix$JULES, 4),
                    beta_day_jules =  round(beta_matrix$JULES, 4),
                   alpha_day_jules = round(alpha_matrix$JULES, 4))
  tab_metrics[is.na(tab_metrics)] <- -9999
  write.table(tab_metrics, file = paste(path, "luts", "LUT_WMO2022_v2_def_plus_ulysses_with_mhm_fixed.txt", sep = "/"),
              quote = F, row.names = F)
  
  # # mHM first 3200 days vs rest
  #   nse_matrix_split <-     nse_matrix %>% filter(!is.na(mHM)) %>% filter(!is.na(V2))
  #   kge_matrix_split <-     kge_matrix %>% filter(!is.na(mHM)) %>% filter(!is.na(V2))
  #     r_matrix_split <-       r_matrix %>% filter(!is.na(mHM)) %>% filter(!is.na(V2))
  #  beta_matrix_split <-    beta_matrix %>% filter(!is.na(mHM)) %>% filter(!is.na(V2))
  # alpha_matrix_split <-   alpha_matrix %>% filter(!is.na(mHM)) %>% filter(!is.na(V2))
  # count_valid_gauge <- sum(!is.na(alpha_matrix_split$mHM))
  # title_text = paste("gauge count: ", count_valid_gauge, sep = "")
  # cols <- c("first 3200 days", "rest")
  # labs <- c("first 3200 days \n (1981 to 06.10.1999) \n", "rest \n (07.10.1999 to 2019)")
  # colnames(  nse_matrix_split) <- cols
  # colnames(  kge_matrix_split) <- cols
  # colnames(    r_matrix_split) <- cols
  # colnames( beta_matrix_split) <- cols
  # colnames(alpha_matrix_split) <- cols
  # # NSE
  # plot_metrics_cdf(melt(nse_matrix_split), paste(path, output_folder, sep = "/"), "cdf_nse_ulysses_120_mhm_ts_split_analysis.png", expression(paste(NSE[day])), c("blue", "red"), hm_lines, labs, title_text, -1, 1, 0.5)
  # # KGE
  # plot_metrics_cdf(melt(kge_matrix_split), paste(path, output_folder, sep = "/"), "cdf_kge_ulysses_120_mhm_ts_split_analysis.png", expression(paste(KGE[day])), c("blue", "red"), hm_lines, labs, title_text, -1, 1, 0.5)
  # # r
  # plot_metrics_cdf(melt(r_matrix_split), paste(path, output_folder, sep = "/"), "cdf_r_ulysses_120_mhm_ts_split_analysis.png", expression(paste(gamma[day])), c("blue", "red"), hm_lines, labs, title_text,  0, 1, 0.25)
  # # beta
  # plot_metrics_cdf(melt(beta_matrix_split), paste(path, output_folder, sep = "/"), "cdf_beta_ulysses_120_mhm_ts_split_analysis.png", expression(paste(beta[day])), c("blue", "red"), hm_lines, labs, title_text,  0, 2, 0.5)
  # # alpha
  # plot_metrics_cdf(melt(alpha_matrix_split), paste(path, output_folder, sep = "/"), "cdf_alpha_ulysses_120_mhm_ts_split_analysis.png", expression(paste(alpha[day])), c("blue", "red"), hm_lines, labs, title_text,  0, 2, 0.5)
  
  # NSE
  plot_metrics_cdf(melt(nse_matrix_common), paste(path, output_folder, sep = "/"), "cdf_nse_wmo_mhm_compare.png", expression(paste(NSE[day])), hm_colors, hm_lines, hm, title_text, -1, 1, 0.5)
  # KGE
  plot_metrics_cdf(melt(kge_matrix_common), paste(path, output_folder, sep = "/"), "cdf_kge_wmo_mhm_compare.png", expression(paste(KGE[day])), hm_colors, hm_lines, hm, title_text, -1, 1, 0.5)
  # r
  plot_metrics_cdf(melt(r_matrix_common), paste(path, output_folder, sep = "/"), "cdf_r_wmo_mhm_compare.png", expression(paste(r[day])), hm_colors, hm_lines, hm, title_text,  0, 1, 0.25)
  # beta
  plot_metrics_cdf(melt(beta_matrix_common), paste(path, output_folder, sep = "/"), "cdf_beta_wmo_mhm_compare.png", expression(paste(beta[day])), hm_colors, hm_lines, hm, title_text,  0, 2, 0.5)
  # alpha
  plot_metrics_cdf(melt(alpha_matrix_common), paste(path, output_folder, sep = "/"), "cdf_alpha_wmo_mhm_compare.png", expression(paste(alpha[day])), hm_colors, hm_lines, hm, title_text,  0, 2, 0.5)

  
  
  # Quick hydrographs across hms (provided q_eval_all is cbind of obs and all sims from q_eval)
  legendnames= c("mHM", "obs", "JULES","PGB")
  mycolors = c("deepskyblue4", "black", "red", "orange")
  plot(q_eval_all_wmo436["/1999"], bty="l" , main = "Station: GRDC ID 4236010 \t\t\t\t\t  NIAGRA RIVER, Queenston, US, 686000 km2",
       cex.main=1, xlab="Time" , ylab="Streamflow (m3.s-1)" , col=mycolors , lwd=1.5 )
  addLegend("top", bty = "o", horiz = "True", legend.names = legendnames, lty=rep(1, 4), lwd=rep(2, 4), col=mycolors)
  
  
  # Quick barplot of beta across stations
  par(mar = c(22, 4.1, 1, 2.1))
  # plot <- barplot(output_matrix$beta~output_matrix$GRDC_id, main = "mHM: 1999 to 2019 minus first 3200 days", ylab=expression(paste(beta[3200]-beta[rest])), xlab="", 
  #         las=2, names.arg = paste(data_lut_extra$river[!is.na(output_matrix$beta)],
  #                                  data_lut_extra$station[!is.na(output_matrix$beta)],
  #                                  data_lut_extra$country[!is.na(output_matrix$beta)],
  #                                  data_lut_extra$grdc_no[!is.na(output_matrix$beta)], sep = " : "), 
  #         cex.axis=1.5, cex.names=0.65, ylim = c(0, 7))
  
    nse_matrix_attrib <- cbind(  nse_matrix,data_lut_extra$grdc_no, data_lut_extra$river, data_lut_extra$station, data_lut_extra$country)
    kge_matrix_attrib <- cbind(  kge_matrix,data_lut_extra$grdc_no, data_lut_extra$river, data_lut_extra$station, data_lut_extra$country)
      r_matrix_attrib <- cbind(    r_matrix,data_lut_extra$grdc_no, data_lut_extra$river, data_lut_extra$station, data_lut_extra$country)
   beta_matrix_attrib <- cbind( beta_matrix,data_lut_extra$grdc_no, data_lut_extra$river, data_lut_extra$station, data_lut_extra$country)
  alpha_matrix_attrib <- cbind(alpha_matrix,data_lut_extra$grdc_no, data_lut_extra$river, data_lut_extra$station, data_lut_extra$country)
  
    nse_matrix_attrib <-   nse_matrix_attrib %>% filter(!is.na(mHM)) %>% filter(!is.na(V2))
    kge_matrix_attrib <-   kge_matrix_attrib %>% filter(!is.na(mHM)) %>% filter(!is.na(V2))
      r_matrix_attrib <-     r_matrix_attrib %>% filter(!is.na(mHM)) %>% filter(!is.na(V2))
   beta_matrix_attrib <-  beta_matrix_attrib %>% filter(!is.na(mHM)) %>% filter(!is.na(V2))
  alpha_matrix_attrib <- alpha_matrix_attrib %>% filter(!is.na(mHM)) %>% filter(!is.na(V2))
  
  grid(nx=10, ny=NULL)
  plot <- barplot((kge_matrix_attrib$V2 - kge_matrix_attrib$mHM)~kge_matrix_attrib[,3], main = "mHM: 1999 to 2019 minus first 3200 days", 
                  ylab=expression(paste(KGE[rest]-KGE[3200])), xlab="", 
                  las=2, names.arg = paste(kge_matrix_attrib[,4],
                                           kge_matrix_attrib[,5],
                                           kge_matrix_attrib[,6],
                                           kge_matrix_attrib[,3], sep = " : "),
                  cex.axis=1.5, cex.names=0.65, ylim = c(-8, 4), plot.grid = T, grid.inc = 1)
  
  plot <- barplot((r_matrix_attrib$V2 - r_matrix_attrib$mHM)~r_matrix_attrib[,3], main = "mHM: 1999 to 2019 minus first 3200 days", 
                  ylab=expression(paste(gamma[rest]-gamma[3200])), xlab="", 
                  las=2, names.arg = paste(r_matrix_attrib[,4],
                                           r_matrix_attrib[,5],
                                           r_matrix_attrib[,6],
                                           r_matrix_attrib[,3], sep = " : "),
                  cex.axis=1.5, cex.names=0.65, ylim = c(-8, 4))
  
  plot <- barplot((beta_matrix_attrib$V2 - beta_matrix_attrib$mHM)~beta_matrix_attrib[,3], main = "mHM: 1999 to 2019 minus first 3200 days", 
                  ylab=expression(paste(beta[rest]-beta[3200])), xlab="", 
                  las=2, names.arg = paste(beta_matrix_attrib[,4],
                                           beta_matrix_attrib[,5],
                                           beta_matrix_attrib[,6],
                                           beta_matrix_attrib[,3], sep = " : "),
                  cex.axis=1.5, cex.names=0.65, ylim = c(-8, 4))
  
  plot <- barplot((alpha_matrix_attrib$V2 - alpha_matrix_attrib$mHM)~alpha_matrix_attrib[,3], main = "mHM: 1999 to 2019 minus first 3200 days", 
                  ylab=expression(paste(alpha[rest]-alpha[3200])), xlab="", 
                  las=2, names.arg = paste(alpha_matrix_attrib[,4],
                                           alpha_matrix_attrib[,5],
                                           alpha_matrix_attrib[,6],
                                           alpha_matrix_attrib[,3], sep = " : "),
                  cex.axis=1.5, cex.names=0.65, ylim = c(-8, 4))
  
  plot <- barplot((nse_matrix_attrib$V2 - nse_matrix_attrib$mHM)~nse_matrix_attrib[,3], main = "mHM: 1999 to 2019 minus first 3200 days", 
                  ylab=expression(paste(NSE[rest]-NSE[3200])), xlab="", 
                  las=2, names.arg = paste(nse_matrix_attrib[,4],
                                           nse_matrix_attrib[,5],
                                           nse_matrix_attrib[,6],
                                           nse_matrix_attrib[,3], sep = " : "),
                  cex.axis=1.5, cex.names=0.65, ylim = c(-8, 4))
  
# plot_metrics_cdf <- function(metric, path, fNameout, metric_name, valid_count, 
#                              metrics_lower_limit, metrics_upper_limit, metrics_interval){
#   
#   # Plotting the graph
#   main <- ggplot() +
#     # CDFs
#     stat_ecdf(data = metric, aes( x= value ), color = "blue", 
#               position = "identity", geom = "line", pad = FALSE, size = 1, alpha = 1, na.rm = TRUE) +
#     # median
#     geom_hline(yintercept = 0.5, color = "black", alpha = 0.3, size = 0.3, linetype = 1) +
#     
#     labs(title = paste("gauges evaluated: ", valid_count, sep = "")) +
#     
#     theme(
#       text=element_text(family = "Helvetica", colour = "black"),
#       axis.ticks.length=unit(-0.2, "cm"),
#       axis.ticks = element_line(colour = "black", size = 0.5),
#       axis.text.x = element_text(size=12, margin = margin(t = 10), colour = "black"),
#       axis.title.x = element_text(size=14, margin = margin(t = 10), colour = "black"),
#       axis.text.y.right = element_text(size=12, margin = margin(l = 10), colour = "black"),
#       axis.title.y.left  = element_text(size=14, margin = margin(r = 15), colour = "black", hjust = c(0.5)),
#       axis.title.y.right = element_blank(),
#       plot.title = element_text(size = 12, colour = "blue", hjust = c(1), margin = margin(b = -10)),
#       panel.border = element_rect(colour = "black", fill=NA, size=1),
#       panel.background = element_blank(),
#       panel.grid.major = element_line(colour = alpha("black", 0.5), size=0.2, linetype = 3),
#       legend.position = c(0.2, 0.80),
#       legend.title = element_blank(),
#       legend.background = element_blank()) +
#     
#     scale_x_continuous(name = metric_name,
#                        breaks = seq(metrics_lower_limit,metrics_upper_limit,metrics_interval), labels = c(seq(metrics_lower_limit,metrics_upper_limit,metrics_interval)),
#                        sec.axis = dup_axis(name ="", labels = c())) +
#     
#     coord_cartesian(xlim = c(metrics_lower_limit, metrics_upper_limit)) +
#     
#     scale_y_continuous(name = "CDF [-]", breaks = seq(0,1,0.2), labels = c(),
#                        sec.axis = dup_axis(name ="", labels = c(seq(0,1,0.2))))
#   
#   # Output
#   ggsave(main, file=paste(path, fNameout, sep="/"), width = 4, height = 4, units = "in", dpi = 300)
#   
# }
