#####################################################################################
##                   ----------------------------------------------------------------
## ==================== mHM simulation metrics plots
##                   ----------------------------------------------------------------
## --- Code developer: 
## ------------------  Pallav Kumar Shrestha pallav-kumar.shrestha@ufz.de ------
## ------------------  29 Aug 2021 ---------------------------------------------
##
## --- Mods: 
##          30 Aug 2021 - Added evaporation check 
##          01 Sep 2021 - Read netcdf instead of output log file; SCC calval
##          02 Sep 2021 - SCC vs Rel for validation period
##          02 Sep 2021 - SCC REL cal val all in one graph. Added 3x terms of KGE
##          15 Sep 2021 - SCC vs D8 n resolved plot
##          17 Sep 2021 - Scalability metrics ensemble box plot
##                      - Metrics stability at ca ratio high and low
##          19 Sep 2021 - SCC vs D8 median surface area of resolved reservoirs plot
#####################################################################################


# Open libraries/ packages
library(ggplot2)
library(reshape) # for melt
library(ncdf4) 
library(chron)
library(xts) 
library(hydroTSM)
library(hydroGOF)
library(dplyr)
library(foreach)    # parallelization
library(doParallel) # parallelization
# Source taylor-made functions
source("/Users/shresthp/git/GitLab/global_mlm/scripts/plots/hydrograph.R")
source("/Users/shresthp/git/GitLab/global_mlm/scripts/plots/metrics_across_domains.R")
source("/Users/shresthp/git/GitLab/global_mlm/scripts/plots/metrics_cdf.R")
source("/Users/shresthp/git/GitLab/global_mlm/scripts/plots/rulecurves.R")


# General control parameters
sim_type = "forward"  # forward, forward_scalability
exp_type <- "compensating_OF60"
dir_name = paste("v8/mlm_2021_v8", sim_type, exp_type, sep = "_") # mlm_2021_fork_scalability_forward_v2, mlm_2021_fork_forward_v2

# sim_dir = paste("/Users/shresthp/tmp/eve_work/work/shresthp/ecflow_mlm2021/", dir_name, "/work/mhm", sep = "")
sim_dir = paste("/Users/shresthp/Nextcloud/Cloud/macbook/01_work/eve/data_from_eve/01_mlm_paper/ecflow_mlm2021/", dir_name, "/work/mhm", sep = "")


lut_file= "/Users/shresthp/tmp/Win7/global_mlm/selection/atable_mlm_global_dam_selection_v1_tm_adj_v3.csv"

scc_dir   = "SCC" 
d8_dir   = "D8" 
rel_dir   = "RELEASE" 
cal_dir   = "cal" 
val_dir   = "val" 
fNamein_q = "discharge.nc" 
fNamein_scc_mlm_fluxesstates = "mLM_Fluxes_States.nc"
fNamein_scc_mhm_fluxesstates = "mHM_Fluxes_States.nc"

fNameout_cdf_kge_all = "q_of_cdf_kge_all.pdf"
fNameout_cdf_alp_all = "q_of_cdf_alpha_all.pdf"
fNameout_cdf_bet_all = "q_of_cdf_beta_all.pdf"
fNameout_cdf_gam_all = "q_of_cdf_gamma_all.pdf"
fNameout_cdf_nse_all = "q_of_cdf_nse_all.pdf"
fNameout_cdf_lognse_all = "q_of_cdf_lognse_all.pdf"

fNameout_diff_lognse = "q_of_diff_lognse.pdf"

fNameout_lake_evap   = "levap_check.pdf"

fNameout_nresolved   = "scc_nresolved.pdf"
fNameout_saresolved   = "scc_saresolved.pdf"
fNameout_cdf_kge_spread = "q_of_cdf_kge_spread.pdf"
fNameout_kge_ens_boxplot = "q_of_bp_kge.pdf"
fNameout_kge_ens_boxplot_stnneardam = "q_of_bp_stnneardam_kge.pdf"
fNameout_kge_ens_boxplot_stnfardam = "q_of_bp_stnfardam_kge.pdf"
fNameout_stability_caratio_low = "q_of_kge_stability_ca_low.pdf"
fNameout_stability_caratio_high = "q_of_kge_stability_ca_high.pdf"

# Resolutions
if (sim_type == "forward_scalability"){
  resolutions = c(seq(0,6)) # exponents of 2
} else {
  resolutions = c(2)
}
nresolutions = length(resolutions)


# Graph parameters
metrics_lower_limit = -1
metrics_interval = 0.5
metrics_stability_lower_limit = 0.2
metrics_ens_lower_limit = 0 #-0.5
metrics_ens_upper_limit = 1 # 1.5
alp_metrics_lower_limit = 0
alp_metrics_upper_limit = 2
alp_metrics_interval    = 0.5
bet_metrics_lower_limit = 0
bet_metrics_upper_limit = 2
bet_metrics_interval    = 0.5
gam_metrics_lower_limit = 0
gam_metrics_upper_limit = 1
gam_metrics_interval    = 0.2

near_far_stn_threshold  = 1.1 

colors_metrics <- c("blue", "blue", "red", "red")
linetypes_metrics <- c(1, 4, 1, 4)
met_upper_limit = 4000
clrs2 <- c("tomato", "blue")
colors_nresolved <- c("blue", "red")
colors_metrics_spread <- c(rep("blue", nresolutions), rep("red", nresolutions))


# ====================== DATA
# Read LUT file
lut_data <- read.delim(lut_file, sep = "," , header = TRUE )

ndomains = length(lut_data$station_id)

# initialize (2D)
met_matrix <- data.frame(matrix(data = NA, nrow = ndomains, ncol = 2))

# initialize (3D)
NaData <- rep(NaN, ndomains*nresolutions*2)
resolved_matrix <- array(NaData, c(ndomains, nresolutions, 2))
kge_matrix <- array(NaData, c(ndomains, nresolutions, 4))
alp_matrix <- array(NaData, c(ndomains, nresolutions, 4))
bet_matrix <- array(NaData, c(ndomains, nresolutions, 4))
gam_matrix <- array(NaData, c(ndomains, nresolutions, 4))
nse_matrix <- array(NaData, c(ndomains, nresolutions, 4))
pbias_matrix <- array(NaData, c(ndomains, nresolutions, 4))
lognse_matrix <- array(NaData, c(ndomains, nresolutions, 4))
sm_lall_avg_matrix <- array(NaData, c(ndomains, nresolutions, 4))




# Get metrics from discharge files

for (idomain in 1: ndomains){
# for (idomain in 34: ndomains){
  
  if(idomain==33) next
  
  # Get meta data
  domainid = lut_data$station_id[idomain]
  damid = lut_data$GRAND_ID[idomain]
  damname <- lut_data$DAM_NAME[idomain]
  damvol <- lut_data$CAP_MCM[idomain]
  damca <- lut_data$CATCH_SKM[idomain]
  damcaratio <- round(lut_data$ds_stn_cr1[idomain], 2)
  
  # Generate title and subtitle for hydrograph
  title_text <- paste(paste("dam: ", damname), paste("gauge: ", domainid), sep = " . ")
  subtitle_text <- paste(paste("dam V: ", damvol, "mcm", sep = " "), paste("c.a. ", damca, "sq.kms. ", sep = " "), 
                         paste("c.a. ratio ", damcaratio), sep = " . ")
  text <- paste("non-dam: ", exp_type, sep = "")
  
  for (ires in 1: nresolutions){
    
    # Get model resolution
    res = c(as.character(format(1/(2^resolutions[ires]), nsmall=1)))
    res_p = gsub("\\.", "p", res)
    
    # Get file paths
    path_1_cal =  paste(sim_dir, domainid, scc_dir, res_p, "output", cal_dir, sep = "/")
    qfile_1_cal = paste(sim_dir, domainid, scc_dir, res_p, "output", cal_dir, fNamein_q, sep = "/")
    mhmfile_1_cal = paste(sim_dir, domainid, scc_dir, res_p, "output", cal_dir, fNamein_scc_mhm_fluxesstates, sep = "/")
    path_1_val =  paste(sim_dir, domainid, scc_dir, res_p, "output", val_dir, sep = "/")
    qfile_1_val = paste(sim_dir, domainid, scc_dir, res_p, "output", val_dir, fNamein_q, sep = "/")
    mhmfile_1_val = paste(sim_dir, domainid, scc_dir, res_p, "output", val_dir, fNamein_scc_mhm_fluxesstates, sep = "/")
    if (sim_type == "forward_scalability"){
      path_2_cal =  paste(sim_dir, domainid, d8_dir, res_p, "output", cal_dir, sep = "/")
      qfile_2_cal = paste(sim_dir, domainid, d8_dir, res_p, "output", cal_dir, fNamein_q, sep = "/")
      mhmfile_2_cal = paste(sim_dir, domainid, d8_dir, res_p, "output", cal_dir, fNamein_scc_mhm_fluxesstates, sep = "/")
      path_2_val =  paste(sim_dir, domainid, d8_dir, res_p, "output", val_dir, sep = "/")
      qfile_2_val = paste(sim_dir, domainid, d8_dir, res_p, "output", val_dir, fNamein_q, sep = "/")
      mhmfile_2_val = paste(sim_dir, domainid, d8_dir, res_p, "output", val_dir, fNamein_scc_mhm_fluxesstates, sep = "/")
    } else {
      path_2_cal =  paste(sim_dir, domainid, rel_dir, res_p, "output", cal_dir, sep = "/")
      qfile_2_cal = paste(sim_dir, domainid, rel_dir, res_p, "output", cal_dir, fNamein_q, sep = "/")
      mhmfile_2_cal = paste(sim_dir, domainid, rel_dir, res_p, "output", cal_dir, fNamein_scc_mhm_fluxesstates, sep = "/")
      path_2_val =  paste(sim_dir, domainid, rel_dir, res_p, "output", val_dir, sep = "/")
      qfile_2_val = paste(sim_dir, domainid, rel_dir, res_p, "output", val_dir, fNamein_q, sep = "/")
      mhmfile_2_val = paste(sim_dir, domainid, rel_dir, res_p, "output", val_dir, fNamein_scc_mhm_fluxesstates, sep = "/")
    }
    
    
    
    if (sim_type == "forward_scalability"){
      
      # resolved ??
      if (file.exists(qfile_1_cal)){
        resolved_matrix[idomain, ires, 1] <- 1
      }
      if (file.exists(qfile_2_cal)){
        resolved_matrix[idomain, ires, 2] <- 1
      }
    }
    
    icount = 0
    maxq_cal = 0
    maxq_val = 0
    while (icount < 2){
      
      
      # Generate title and subtitle for hydrograph
      title_text <- paste(paste("dam: ", damname), paste("gauge: ", domainid), sep = " . ")
      subtitle_text <- paste(paste("dam V: ", damvol, "mcm", sep = " "), paste("c.a. ", damca, "sq.kms. ", sep = " "), 
                             paste("c.a. ratio ", damcaratio), sep = " . ")
      text <- paste("non-dam: ", exp_type, sep = "")
      
      
      icount = icount + 1
      #  ==  First set (SCC)
      
      # ---- Calibration
      # check whether the q files exist
      if (file.exists(qfile_1_cal)){
        # Read the netCDF file
        ncin <- nc_open(qfile_1_cal)
        # get VARIABLES names
        varnames <- names(ncin$var)
        # get Time Series data
        q_sim <- as.numeric(ncvar_get(ncin,varnames[1]))  # [gauge, time]
        q_obs <- as.numeric(ncvar_get(ncin,varnames[2]))  # [gauge, time]
        # Close the netCDF file
        nc_close(ncin)
        # Calculate and store metrics
        kge_matrix[idomain, ires, 1] <- KGE(q_sim, q_obs, na.rm = TRUE)
        kge_terms <- as.numeric(unlist(KGE(q_sim, q_obs, na.rm = TRUE, out.type = "full")[2]))
        gam_matrix[idomain, ires, 1] <- kge_terms[1]
        bet_matrix[idomain, ires, 1] <- kge_terms[2]
        alp_matrix[idomain, ires, 1] <- kge_terms[3]
        nse_matrix[idomain, ires, 1] <- NSeff(q_sim, q_obs, na.rm = TRUE)
        pbias_matrix[idomain, ires, 1] <- pbias(q_sim, q_obs, na.rm = TRUE)
        q_obs[q_obs <= 0] <- NA # to avoid the log(0) issue
        lognse_matrix[idomain, ires, 1] <- NSeff(log(q_sim), log(q_obs), na.rm = TRUE)
        
        # Plot and store hydrograph
        # plot_hydrograph(path_1_cal, domainid, "Calibration")
        caption_text <- paste("dam: calibration", text, sep = " . ")
        if (maxq_cal < max(quantile(q_sim, 0.95, na.rm = TRUE), quantile(q_obs, 0.95, na.rm = TRUE), na.rm = TRUE)){
          maxq_cal = max(quantile(q_sim, 0.95, na.rm = TRUE), quantile(q_obs, 0.95, na.rm = TRUE), na.rm = TRUE)
        }
        plot_hydrograph(path_1_cal, domainid, title_text, subtitle_text, caption_text, maxq_cal)
        plot_rulecurve(path_1_cal, damid, title_text, subtitle_text, caption_text)
      }
      # check whether the mhm FS files exist
      if (file.exists(mhmfile_1_cal)){
        # Read the netCDF file
        ncin <- nc_open(mhmfile_1_cal)
        # get VARIABLE
        sm_lall_3d <- ncvar_get(ncin, "SM_Lall")  # [lon, lat, time]
        # Read time attribute
        nctime <- ncvar_get(ncin,"time")
        nt <- dim(nctime)
        # Close the netCDF file
        nc_close(ncin)
        # Calculate and store basin average SM
        sm_lall_avg_matrix[idomain, ires, 1] <- mean(sm_lall_3d[,,], na.rm = TRUE)
        # # Calculate and store basin average SM time series
        # # initialize
        # sm_lall_1d <- vector()
        # foreach (itime = 1:nt) %do% {
        #   # # MASK
        #   # data_3d[,,itime] <- ifelse(mask < 0, NA, data_3d[,,itime])
        #   # FLDMEAN
        #   sm_lall_1d[itime] <- mean(sm_lall_3d[,,itime], na.rm = TRUE)
        # }
      }
      
      # ---- Validation
      # check whether the q files exist
      if (file.exists(qfile_1_val)){
        # Read the netCDF file
        ncin <- nc_open(qfile_1_val)
        # get VARIABLES names
        varnames <- names(ncin$var)
        # get Time Series data
        q_sim <- as.numeric(ncvar_get(ncin,varnames[1]))  # [gauge, time]
        q_obs <- as.numeric(ncvar_get(ncin,varnames[2]))  # [gauge, time]
        # Close the netCDF file
        nc_close(ncin)
        # Calculate and store metrics
        kge_matrix[idomain, ires, 2] <- KGE(q_sim, q_obs, na.rm = TRUE)
        kge_terms <- as.numeric(unlist(KGE(q_sim, q_obs, na.rm = TRUE, out.type = "full")[2]))
        gam_matrix[idomain, ires, 2] <- kge_terms[1]
        bet_matrix[idomain, ires, 2] <- kge_terms[2]
        alp_matrix[idomain, ires, 2] <- kge_terms[3]
        nse_matrix[idomain, ires, 2] <- NSeff(q_sim, q_obs, na.rm = TRUE)
        pbias_matrix[idomain, ires, 2] <- pbias(q_sim, q_obs, na.rm = TRUE)
        q_obs[q_obs <= 0] <- NA # to avoid the log(0) issue
        lognse_matrix[idomain, ires, 2] <- NSeff(log(q_sim), log(q_obs), na.rm = TRUE)
        # Plot and store hydrograph
        caption_text <- paste("dam: validation", text, sep = " . ")
        if (maxq_val < max(quantile(q_sim, 0.95, na.rm = TRUE), quantile(q_obs, 0.95, na.rm = TRUE), na.rm = TRUE)){
          maxq_val = max(quantile(q_sim, 0.95, na.rm = TRUE), quantile(q_obs, 0.95, na.rm = TRUE), na.rm = TRUE)
        }
        plot_hydrograph(path_1_val, domainid, title_text, subtitle_text, caption_text, maxq_val)
      }
      # check whether the mhm FS files exist
      if (file.exists(mhmfile_1_val)){
        # Read the netCDF file
        ncin <- nc_open(mhmfile_1_val)
        # get VARIABLE
        sm_lall_3d <- ncvar_get(ncin, "SM_Lall")  # [lon, lat, time]
        # Read time attribute
        nctime <- ncvar_get(ncin,"time")
        nt <- dim(nctime)
        # Close the netCDF file
        nc_close(ncin)
        # Calculate and store basin average SM
        sm_lall_avg_matrix[idomain, ires, 2] <- mean(sm_lall_3d[,,], na.rm = TRUE)
      }
      
      
      # ==  Second Set (Release for Forward and D8 for Scalability Forward)
      
      # ---- Calibration
      # check whether the q files exist
      if (file.exists(qfile_2_cal)){
        # Read the netCDF file
        ncin <- nc_open(qfile_2_cal)
        # get VARIABLES names
        varnames <- names(ncin$var)
        # get Time Series data
        q_sim <- as.numeric(ncvar_get(ncin,varnames[1]))  # [gauge, time]
        q_obs <- as.numeric(ncvar_get(ncin,varnames[2]))  # [gauge, time]
        # Close the netCDF file
        nc_close(ncin)
        # Calculate and store metrics
        kge_matrix[idomain, ires, 3] <- KGE(q_sim, q_obs, na.rm = TRUE)
        kge_terms <- as.numeric(unlist(KGE(q_sim, q_obs, na.rm = TRUE, out.type = "full")[2]))
        gam_matrix[idomain, ires, 3] <- kge_terms[1]
        bet_matrix[idomain, ires, 3] <- kge_terms[2]
        alp_matrix[idomain, ires, 3] <- kge_terms[3]
        nse_matrix[idomain, ires, 3] <- NSeff(q_sim, q_obs, na.rm = TRUE)
        pbias_matrix[idomain, ires, 3] <- pbias(q_sim, q_obs, na.rm = TRUE)
        q_obs[q_obs <= 0] <- NA # to avoid the log(0) issue
        lognse_matrix[idomain, ires, 3] <- NSeff(log(q_sim), log(q_obs), na.rm = TRUE)
        # Plot and store hydrograph
        caption_text <- paste("dam: NA", text, sep = " . ")
        title_text <- paste("gauge: ", domainid)
        subtitle_text <- ""
        if (maxq_cal < max(quantile(q_sim, 0.95, na.rm = TRUE), quantile(q_obs, 0.95, na.rm = TRUE), na.rm = TRUE)){
          maxq_cal = max(quantile(q_sim, 0.95, na.rm = TRUE), quantile(q_obs, 0.95, na.rm = TRUE), na.rm = TRUE)
        }
        plot_hydrograph(path_2_cal, domainid, title_text, subtitle_text, caption_text, 0.5 * maxq_cal)
      }
      # check whether the mhm FS files exist
      if (file.exists(mhmfile_2_cal)){
        # Read the netCDF file
        ncin <- nc_open(mhmfile_2_cal)
        # get VARIABLE
        sm_lall_3d <- ncvar_get(ncin, "SM_Lall")  # [lon, lat, time]
        # Read time attribute
        nctime <- ncvar_get(ncin,"time")
        nt <- dim(nctime)
        # Close the netCDF file
        nc_close(ncin)
        # Calculate and store basin average SM
        sm_lall_avg_matrix[idomain, ires, 3] <- mean(sm_lall_3d[,,], na.rm = TRUE)
      }
      
      # ---- Validation
      # check whether the q files exist
      if (file.exists(qfile_2_val)){
        # Read the netCDF file
        ncin <- nc_open(qfile_2_val)
        # get VARIABLES names
        varnames <- names(ncin$var)
        # get Time Series data
        q_sim <- as.numeric(ncvar_get(ncin,varnames[1]))  # [gauge, time]
        q_obs <- as.numeric(ncvar_get(ncin,varnames[2]))  # [gauge, time]
        # Close the netCDF file
        nc_close(ncin)
        # Calculate and store metrics
        kge_matrix[idomain, ires, 4] <- KGE(q_sim, q_obs, na.rm = TRUE)
        kge_terms <- as.numeric(unlist(KGE(q_sim, q_obs, na.rm = TRUE, out.type = "full")[2]))
        gam_matrix[idomain, ires, 4] <- kge_terms[1]
        bet_matrix[idomain, ires, 4] <- kge_terms[2]
        alp_matrix[idomain, ires, 4] <- kge_terms[3]
        nse_matrix[idomain, ires, 4] <- NSeff(q_sim, q_obs, na.rm = TRUE)
        pbias_matrix[idomain, ires, 4] <- pbias(q_sim, q_obs, na.rm = TRUE)
        q_obs[q_obs <= 0] <- NA # to avoid the log(0) issue
        lognse_matrix[idomain, ires, 4] <- NSeff(log(q_sim), log(q_obs), na.rm = TRUE)
        # Plot and store hydrograph
        caption_text <- paste("dam: NA", text, sep = " . ")
        title_text <- paste("gauge: ", domainid)
        subtitle_text <- ""
        if (maxq_val < max(quantile(q_sim, 0.95, na.rm = TRUE), quantile(q_obs, 0.95, na.rm = TRUE), na.rm = TRUE)){
          maxq_val = max(quantile(q_sim, 0.95, na.rm = TRUE), quantile(q_obs, 0.95, na.rm = TRUE), na.rm = TRUE)
        }
        plot_hydrograph(path_2_val, domainid, title_text, subtitle_text, caption_text, maxq_val)
      }
      # check whether the mhm FS files exist
      if (file.exists(mhmfile_2_val)){
        # Read the netCDF file
        ncin <- nc_open(mhmfile_2_val)
        # get VARIABLE
        sm_lall_3d <- ncvar_get(ncin, "SM_Lall")  # [lon, lat, time]
        # Read time attribute
        nctime <- ncvar_get(ncin,"time")
        nt <- dim(nctime)
        # Close the netCDF file
        nc_close(ncin)
        # Calculate and store basin average SM
        sm_lall_avg_matrix[idomain, ires, 2] <- mean(sm_lall_3d[,,], na.rm = TRUE)
      }
    
    }
    
  } # resolution loop
  
  print(paste(idomain, domainid, sep = " "))
}

# Combine Hydrographs
system(paste("convert -density 150 $(ls -rt ", sim_dir,"/*/SCC/*/*/cal/*_hydrograph.pdf) ", sim_dir,"/hydrographs_scc_cal.pdf", sep = ""))
system(paste("convert -density 150 $(ls -rt ", sim_dir,"/*/RELEASE/*/*/cal/*_hydrograph.pdf) ", sim_dir,"/hydrographs_rel_cal.pdf", sep = ""))
system(paste("convert -density 150 $(ls -rt ", sim_dir,"/*/SCC/*/*/val/*_hydrograph.pdf) ", sim_dir,"/hydrographs_scc_val.pdf", sep = ""))
system(paste("convert -density 150 $(ls -rt ", sim_dir,"/*/RELEASE/*/*/val/*_hydrograph.pdf) ", sim_dir,"/hydrographs_rel_val.pdf", sep = ""))
# Combine Rule curves
system(paste("convert -density 150 $(ls -rt ", sim_dir,"/*/SCC/*/*/cal/*_rulecurve.pdf) ", sim_dir,"/rulecurves_scc_cal.pdf", sep = ""))



# add colnames
resnames <- c(format(lapply(seq(1:nresolutions), function(x) 1/2^(x-1)), nsmall = 1)) 
resnames_sel <- c(format(lapply(c(3,4,5,6,7), function(x) 1/2^(x-1)), nsmall = 1)) 
colnames(kge_matrix) <- resnames
colnames(alp_matrix) <- resnames
colnames(bet_matrix) <- resnames
colnames(gam_matrix) <- resnames
colnames(nse_matrix) <- resnames
colnames(lognse_matrix) <- resnames
colnames(sm_lall_avg_matrix) <- resnames


# number of domains with valid set of metrics 
kge_matrix[kge_matrix == 'NaN'] <- NA
ndomains_valid_scc <- sum(!is.na(kge_matrix[,1,1]))
ndomains_valid_rel <- sum(!is.na(kge_matrix[,1,3]))
# ndomains_valid_scc <- ""
# ndomains_valid_rel <- ""



if (sim_type == "forward_scalability"){
  
  ## --  Number of Reservoirs RESOLVED  --
  nresolved <- rev(apply(resolved_matrix[,,1], 2, function(x) sum(!is.na(x))))
  nresolved <- cbind(nresolved, rev(apply(resolved_matrix[,,2], 2, function(x) sum(!is.na(x)))))
  colnames(nresolved) <- c("SCC", "D8")
  nresolved <- nresolved/ndomains*100
  nresolved_melt <- melt(nresolved)
  
  ## --  Median Reservoir SURFACE AREA of Reservoirs RESOLVED  --
  saresolved <- rev(apply(resolved_matrix[,,1]*lut_data$AREA_SKM, 2, function(x) median(x, na.rm = TRUE)))
  saresolved <- cbind(saresolved, rev(apply(resolved_matrix[,,2]*lut_data$AREA_SKM, 2, function(x) median(x, na.rm = TRUE))))
  colnames(saresolved) <- c("SCC", "D8")
  saresolved_melt <- melt(saresolved)
  
  
  ## --  Metrics ENSEMBLE (Box Plots)  --
  
  # ALL dams
  # SCC ensemble metrics
  kge_ensemble_scc_melt <- melt(kge_matrix[,,1]) # SCC cal
  kge_ensemble_scc_melt$X1 <- "SCC"
  # D8 ensemble metrics
  kge_ensemble_d8_melt <- melt(kge_matrix[,,3]) # D8 cal
  kge_ensemble_d8_melt$X1 <- "D8"
  # combine melts
  kge_ensemble_melt <- rbind(kge_ensemble_scc_melt, kge_ensemble_d8_melt)
  
  # -- Dams with close Q station
  kge_matrix_stnneardam <- kge_matrix[lut_data$ds_stn_cr1 < near_far_stn_threshold,,c(1,3)]
  # SCC ensemble metrics
  kge_matrix_scc_stnneardam_sel <- kge_matrix_stnneardam[!is.na(kge_matrix_stnneardam[,3,1]) & !is.na(kge_matrix_stnneardam[,3,2]),3:5,1]
  kge_matrix_scc_stnneardam_sel_melt <- melt(kge_matrix_scc_stnneardam_sel)
  kge_matrix_scc_stnneardam_sel_melt$X1 <- "SCC"
  # D8 ensemble metrics
  kge_matrix_d8_stnneardam_sel <- kge_matrix_stnneardam[!is.na(kge_matrix_stnneardam[,3,1]) & !is.na(kge_matrix_stnneardam[,3,2]),3:5,2]
  kge_matrix_d8_stnneardam_sel_melt <- melt(kge_matrix_d8_stnneardam_sel)
  kge_matrix_d8_stnneardam_sel_melt$X1 <- "D8"
  # Combine
  kge_matrix_stnneardam_sel_melt <- rbind(kge_matrix_scc_stnneardam_sel_melt, kge_matrix_d8_stnneardam_sel_melt)
  n_kge_matrix_stnneardam_sel <- length(kge_matrix_scc_stnneardam_sel[,1])
  # # Medians
  # kge_matrix_d8_stnneardam_sel_median <- apply(kge_matrix_d8_stnneardam_sel, 2, function(x) median(x, na.rm = TRUE))
  # kge_matrix_scc_stnneardam_sel_median <- apply(kge_matrix_scc_stnneardam_sel, 2, function(x) median(x, na.rm = TRUE))
  # kge_matrix_stnneardam_sel_median <- rbind(kge_matrix_scc_stnneardam_sel_median, kge_matrix_d8_stnneardam_sel_median)
  # rownames(kge_matrix_stnneardam_sel_median) <- c("SCC", "D8")
  # kge_matrix_stnneardam_sel_median_melt <- melt(kge_matrix_stnneardam_sel_median)
  
  # --Dams with far Q station
  kge_matrix_stnfardam  <- kge_matrix[lut_data$ds_stn_cr1 >= near_far_stn_threshold,,c(1,3)]
  # SCC ensemble metrics
  kge_matrix_scc_stnfardam_sel <- kge_matrix_stnfardam[!is.na(kge_matrix_stnfardam[,3,1]) & !is.na(kge_matrix_stnfardam[,3,2]),3:5,1]
  kge_matrix_scc_stnfardam_sel_melt <- melt(kge_matrix_scc_stnfardam_sel)
  kge_matrix_scc_stnfardam_sel_melt$X1 <- "SCC"
  # D8 ensemble metrics
  kge_matrix_d8_stnfardam_sel <- kge_matrix_stnfardam[!is.na(kge_matrix_stnfardam[,3,1]) & !is.na(kge_matrix_stnfardam[,3,2]),3:5,2]
  kge_matrix_d8_stnfardam_sel_melt <- melt(kge_matrix_d8_stnfardam_sel)
  kge_matrix_d8_stnfardam_sel_melt$X1 <- "D8"
  # Combine
  kge_matrix_stnfardam_sel_melt <- rbind(kge_matrix_scc_stnfardam_sel_melt, kge_matrix_d8_stnfardam_sel_melt)
  n_kge_matrix_stnfardam_sel <- length(kge_matrix_scc_stnfardam_sel[,1])
  # # Medians
  # kge_matrix_scc_stnfardam_sel_median <- apply(kge_matrix_scc_stnfardam_sel, 2, function(x) median(x, na.rm = TRUE))
  # kge_matrix_d8_stnfardam_sel_median <- apply(kge_matrix_d8_stnfardam_sel, 2, function(x) median(x, na.rm = TRUE))
  # kge_matrix_stnfardam_sel_median <- rbind(kge_matrix_scc_stnfardam_sel_median, kge_matrix_d8_stnfardam_sel_median)
  # rownames(kge_matrix_stnfardam_sel_median) <- c("SCC", "D8")
  # kge_matrix_stnfardam_sel_median_melt <- melt(kge_matrix_stnfardam_sel_median)
  
  
  ## --  Metrics STABILITY  --
  # Chungju, S Korea [9]
  kge_chungju_melt <- melt(kge_matrix[9,,c(1,3)]) 
  # Tres Marias, Brazil [77]
  kge_tresmarias_melt <- melt(kge_matrix[77,,c(1,3)]) 
  
  
  ## (not used) --  Most COARSE Resolving RESOLUTION for reservoirs  --
  dummy <- apply(is.na(resolved_matrix[,,1]), 1, which.min) # index of first not NA
  most_coarse_resolved_res <- 1/2^(dummy - 1)
  dummy <- apply(is.na(resolved_matrix[,,2]), 1, which.min) # index of first not NA
  dummy <- 1/2^(dummy - 1)
  most_coarse_resolved_res <- cbind(lut_data$AREA_SKM, most_coarse_resolved_res, dummy)
  colnames(most_coarse_resolved_res) <- c("AREA_SKM", "SCC", "D8" )
  most_coarse_resolved_res <- as.data.frame(most_coarse_resolved_res)
  arrange(most_coarse_resolved_res, AREA_SKM)
  most_coarse_resolved_res_melt <- melt(most_coarse_resolved_res)
  
}


# MELT as required in each graph

## ---  using all KGE sets in one graph
kge_matrix_melt_all <- melt(kge_matrix)
alp_matrix_melt_all <- melt(alp_matrix)
bet_matrix_melt_all <- melt(bet_matrix)
gam_matrix_melt_all <- melt(gam_matrix)
nse_matrix_melt_all <- melt(nse_matrix)
lognse_matrix_melt_all <- melt(lognse_matrix)
## ---  using only cal KGE sets in one graph
kge_matrix_melt_spread <- melt(kge_matrix[,,c(1,3)])
nse_matrix_melt_spread <- melt(nse_matrix[,,c(1,3)])
lognse_matrix_melt_spread <- melt(lognse_matrix[,,c(1,3)])

## ---  box plot across scales
# kge_matrix_melt_spread_stnneardam <- melt(kge_matrix[lut_data$ds_stn_cr1 < near_far_stn_threshold,,c(1,3)])
# nse_matrix_melt_spread_stnneardam <- melt(nse_matrix[lut_data$ds_stn_cr1 < near_far_stn_threshold,,c(1,3)])
# kge_matrix_melt_spread_stnfardam <- melt(kge_matrix[lut_data$ds_stn_cr1 >= near_far_stn_threshold,,c(1,3)])
# nse_matrix_melt_spread_stnfardam <- melt(nse_matrix[lut_data$ds_stn_cr1 >= near_far_stn_threshold,,c(1,3)])

## ---  metrics across dams
nse_dams <- data.frame(name = lut_data$DAM_NAME, scc_cal = nse_matrix[,1,1], scc_val = nse_matrix[,1,2], rel_cal = nse_matrix[,1,3], rel_val = nse_matrix[,1,4])
kge_dams <- data.frame(name = lut_data$DAM_NAME, scc_cal = kge_matrix[,1,1], scc_val = kge_matrix[,1,2], rel_cal = kge_matrix[,1,3], rel_val = kge_matrix[,1,4])
gam_dams <- data.frame(name = lut_data$DAM_NAME, scc_cal = gam_matrix[,1,1], scc_val = gam_matrix[,1,2], rel_cal = gam_matrix[,1,3], rel_val = gam_matrix[,1,4])
bet_dams <- data.frame(name = lut_data$DAM_NAME, scc_cal = bet_matrix[,1,1], scc_val = bet_matrix[,1,2], rel_cal = bet_matrix[,1,3], rel_val = bet_matrix[,1,4])
alp_dams <- data.frame(name = lut_data$DAM_NAME, scc_cal = alp_matrix[,1,1], scc_val = alp_matrix[,1,2], rel_cal = alp_matrix[,1,3], rel_val = alp_matrix[,1,4])
lognse_dams <- data.frame(name = lut_data$DAM_NAME, scc_cal = lognse_matrix[,1,1], scc_val = lognse_matrix[,1,2], rel_cal = lognse_matrix[,1,3], rel_val = lognse_matrix[,1,4])
pbias_dams <- data.frame(name = lut_data$DAM_NAME, scc_cal = pbias_matrix[,1,1], scc_val = pbias_matrix[,1,2], rel_cal = pbias_matrix[,1,3], rel_val = pbias_matrix[,1,4])

## ---  metrics across dams (diff SCC vs RELEASE)
diff_nse_dams <- data.frame(name = lut_data$DAM_NAME, cal_diff = nse_matrix[,1,1] - nse_matrix[,1,3], val_diff = nse_matrix[,1,2] - nse_matrix[,1,4])
diff_kge_dams <- data.frame(name = lut_data$DAM_NAME, cal_diff = kge_matrix[,1,1] - kge_matrix[,1,3], val_diff = kge_matrix[,1,2] - kge_matrix[,1,4])
diff_gam_dams <- data.frame(name = lut_data$DAM_NAME, cal_diff = gam_matrix[,1,1] - gam_matrix[,1,3], val_diff = gam_matrix[,1,2] - gam_matrix[,1,4])
diff_bet_dams <- data.frame(name = lut_data$DAM_NAME, cal_diff = bet_matrix[,1,1] - bet_matrix[,1,3], val_diff = bet_matrix[,1,2] - bet_matrix[,1,4])
diff_alp_dams <- data.frame(name = lut_data$DAM_NAME, cal_diff = alp_matrix[,1,1] - alp_matrix[,1,3], val_diff = alp_matrix[,1,2] - alp_matrix[,1,4])
diff_lognse_dams <- data.frame(name = lut_data$DAM_NAME, cal_diff = lognse_matrix[,1,1] - lognse_matrix[,1,3], val_diff = lognse_matrix[,1,2] - lognse_matrix[,1,4])
diff_pbias_dams <- data.frame(name = lut_data$DAM_NAME, cal_diff = pbias_matrix[,1,1] - pbias_matrix[,1,3], val_diff = pbias_matrix[,1,2] - pbias_matrix[,1,4])





# Get simulated lake evaporation

for (idomain in 1: ndomains){
  
  domainid = lut_data$station_id[idomain]
  mlm_nc_file = paste(sim_dir, domainid, "output_scc", fNamein_scc_mlm_fluxesstates , sep = "/")
  
  # check whether the netCDF file exists
  if (file.exists(mlm_nc_file)){
    
    # Read the netCDF file
    ncin <- nc_open(mlm_nc_file)
    # get VARIABLE
    lake_evap<- ncvar_get(ncin,"Levap")  # [dam, time]
    lake_pre<- ncvar_get(ncin,"Lpre")  # [dam, time]
    # Read time attribute
    nctime <- ncvar_get(ncin,"time")
    tunits <- ncatt_get(ncin,"time","units")
    nt <- dim(nctime)
    # Prepare the time origin
    tustr <- strsplit(tunits$value, " ")
    tdstr <- strsplit(unlist(tustr)[3], "-")
    tmonth <- as.integer(unlist(tdstr)[2])
    tday <- as.integer(unlist(tdstr)[3])
    tyear <- as.integer(unlist(tdstr)[1])
    tfinal <- as.Date(chron(nctime/24, origin=c(tmonth, tday, tyear))) # nctime (days)
    # convert to xts
    lake_evap_xts <- xts(as.numeric(lake_evap), order.by = tfinal) # xts/ time series object created
    lake_pre_xts <- xts(as.numeric(lake_pre), order.by = tfinal)
    # convert to yearly
    lake_evap_annual <- as.matrix(daily2annual(lake_evap_xts, FUN = sum, na.rm = FALSE))
    lake_pre_annual <- as.matrix(daily2annual(lake_pre_xts, FUN = sum, na.rm = FALSE))
    # get annual mean
    lake_evap_annual <- mean(lake_evap_annual, na.rm = TRUE)
    lake_pre_annual <- mean(lake_pre_annual, na.rm = TRUE)
    # Store annual mean values
    met_matrix[idomain, 1] <- lake_evap_annual
    met_matrix[idomain, 2] <- lake_pre_annual
    
  }
  print(paste(idomain, domainid, sep = " "))
}


# add colnames
colnames(met_matrix) <- c("evap","pre")

# melt
met_matrix_melt <- melt(met_matrix)




# ====================== GRAPHS


if (sim_type == "forward"){

  # ====================================================
  # CDF Plots
  # ====================================================
  
  # KGE
  plot_metrics_cdf(kge_matrix_melt_all, sim_dir, "cdf_kge.pdf", expression(paste(KGE[day])), colors_metrics, linetypes_metrics, metrics_lower_limit, 1, metrics_interval)
  # Alpha
  plot_metrics_cdf(alp_matrix_melt_all, sim_dir, "cdf_alpha.pdf", expression(paste(alpha[day])), colors_metrics, linetypes_metrics, alp_metrics_lower_limit, alp_metrics_upper_limit, alp_metrics_interval)
  # Beta
  plot_metrics_cdf(bet_matrix_melt_all, sim_dir, "cdf_beta.pdf", expression(paste(beta[day])), colors_metrics, linetypes_metrics, bet_metrics_lower_limit, bet_metrics_upper_limit, bet_metrics_interval)
  # Gamma
  plot_metrics_cdf(gam_matrix_melt_all, sim_dir, "cdf_gamma.pdf", expression(paste(gamma[day])), colors_metrics, linetypes_metrics, gam_metrics_lower_limit, gam_metrics_upper_limit, gam_metrics_interval)
  # NSE
  plot_metrics_cdf(nse_matrix_melt_all, sim_dir, "cdf_nse.pdf", expression(paste(NSE[day])), colors_metrics, linetypes_metrics, metrics_lower_limit, 1, metrics_interval)
  # logNSE
  plot_metrics_cdf(lognse_matrix_melt_all, sim_dir, "cdf_lognse.pdf", expression(paste(logNSE[day])), colors_metrics, linetypes_metrics, metrics_lower_limit, 1, metrics_interval)
  
  
  # Combine
  system(paste("convert -density 150 $(ls -rt ", sim_dir,"/cdf_*.pdf) ", sim_dir,"/cdf.pdf", sep = ""))
  # Remove individual files
  system(paste("rm ", sim_dir,"/cdf_*.pdf", sep = ""))
  
  
  # ==========================
  # Metrics across dams (MAD) plots
  # ==========================
  
  # SCC - calibration
  
  # logNSE
  plot_metrics_across_domains(lognse_dams, sim_dir, "mad_lognse_scc_cal.pdf", lognse_dams$name, lognse_dams$scc_cal, "Dam", "log NSE", c(-1, 1))
  # NSE
  plot_metrics_across_domains(nse_dams, sim_dir, "mad_nse_scc_cal.pdf", nse_dams$name, nse_dams$scc_cal, "Dam", "NSE", c(-1, 1))
  # KGE
  plot_metrics_across_domains(kge_dams, sim_dir, "mad_kge_scc_cal.pdf", kge_dams$name, kge_dams$scc_cal, "Dam", "KGE", c(-1, 1))
  # Gamma
  plot_metrics_across_domains(gam_dams, sim_dir, "mad_gamma_scc_cal.pdf", gam_dams$name, gam_dams$scc_cal, "Dam", expression(paste(gamma)), c(0, 1))
  # Beta
  plot_metrics_across_domains(bet_dams, sim_dir, "mad_beta_scc_cal.pdf", bet_dams$name, bet_dams$scc_cal, "Dam", expression(paste(beta)), c(0, 2))
  # Alpha
  plot_metrics_across_domains(alp_dams, sim_dir, "mad_alpha_scc_cal.pdf", alp_dams$name, alp_dams$scc_cal, "Dam", expression(paste(alpha)), c(0, 2))
  # PBIAS
  plot_metrics_across_domains(pbias_dams, sim_dir, "mad_pbias_scc_cal.pdf", pbias_dams$name, pbias_dams$scc_cal, "Dam", "PBIAS", c(-50, 50))
  
  # SCC - validation
  
  # logNSE
  plot_metrics_across_domains(lognse_dams, sim_dir, "mad_lognse_scc_val.pdf", lognse_dams$name, lognse_dams$scc_val, "Dam", "log NSE", c(-1, 1))
  # NSE
  plot_metrics_across_domains(nse_dams, sim_dir, "mad_nse_scc_val.pdf", nse_dams$name, nse_dams$scc_val, "Dam", "NSE", c(-1, 1))
  # KGE
  plot_metrics_across_domains(kge_dams, sim_dir, "mad_kge_scc_val.pdf", kge_dams$name, kge_dams$scc_val, "Dam", "KGE", c(-1, 1))
  # Gamma
  plot_metrics_across_domains(gam_dams, sim_dir, "mad_gamma_scc_val.pdf", gam_dams$name, gam_dams$scc_val, "Dam", expression(paste(gamma)), c(0, 1))
  # Beta
  plot_metrics_across_domains(bet_dams, sim_dir, "mad_beta_scc_val.pdf", bet_dams$name, bet_dams$scc_val, "Dam", expression(paste(beta)), c(0, 2))
  # Alpha
  plot_metrics_across_domains(alp_dams, sim_dir, "mad_alpha_scc_val.pdf", alp_dams$name, alp_dams$scc_val, "Dam", expression(paste(alpha)), c(0, 2))
  # PBIAS
  plot_metrics_across_domains(pbias_dams, sim_dir, "mad_pbias_scc_val.pdf", pbias_dams$name, pbias_dams$scc_val, "Dam", "PBIAS", c(-50, 50))
  
  # RELEASE - calibration
  
  # logNSE
  plot_metrics_across_domains(lognse_dams, sim_dir, "mad_lognse_rel_val.pdf", lognse_dams$name, lognse_dams$rel_val, "Dam", "log NSE", c(-1, 1))
  # NSE
  plot_metrics_across_domains(nse_dams, sim_dir, "mad_nse_rel_val.pdf", nse_dams$name, nse_dams$rel_val, "Dam", "NSE", c(-1, 1))
  # KGE
  plot_metrics_across_domains(kge_dams, sim_dir, "mad_kge_rel_val.pdf", kge_dams$name, kge_dams$rel_val, "Dam", "KGE", c(-1, 1))
  # Gamma
  plot_metrics_across_domains(gam_dams, sim_dir, "mad_gamma_rel_val.pdf", gam_dams$name, gam_dams$rel_val, "Dam", expression(paste(gamma)), c(0, 1))
  # Beta
  plot_metrics_across_domains(bet_dams, sim_dir, "mad_beta_rel_val.pdf", bet_dams$name, bet_dams$rel_val, "Dam", expression(paste(beta)), c(0, 2))
  # Alpha
  plot_metrics_across_domains(alp_dams, sim_dir, "mad_alpha_rel_val.pdf", alp_dams$name, alp_dams$rel_val, "Dam", expression(paste(alpha)), c(0, 2))
  # PBIAS
  plot_metrics_across_domains(pbias_dams, sim_dir, "mad_pbias_rel_val.pdf", pbias_dams$name, pbias_dams$rel_val, "Dam", "PBIAS", c(-50, 50))
  
  # RELEASE - validation
  
  # logNSE
  plot_metrics_across_domains(lognse_dams, sim_dir, "mad_lognse_rel_cal.pdf", lognse_dams$name, lognse_dams$rel_cal, "Dam", "log NSE", c(-1, 1))
  # NSE
  plot_metrics_across_domains(nse_dams, sim_dir, "mad_nse_rel_cal.pdf", nse_dams$name, nse_dams$rel_cal, "Dam", "NSE", c(-1, 1))
  # KGE
  plot_metrics_across_domains(kge_dams, sim_dir, "mad_kge_rel_cal.pdf", kge_dams$name, kge_dams$rel_cal, "Dam", "KGE", c(-1, 1))
  # Gamma
  plot_metrics_across_domains(gam_dams, sim_dir, "mad_gamma_rel_cal.pdf", gam_dams$name, gam_dams$rel_cal, "Dam", expression(paste(gamma)), c(0, 1))
  # Beta
  plot_metrics_across_domains(bet_dams, sim_dir, "mad_beta_rel_cal.pdf", bet_dams$name, bet_dams$rel_cal, "Dam", expression(paste(beta)), c(0, 2))
  # Alpha
  plot_metrics_across_domains(alp_dams, sim_dir, "mad_alpha_rel_cal.pdf", alp_dams$name, alp_dams$rel_cal, "Dam", expression(paste(alpha)), c(0, 2))
  # PBIAS
  plot_metrics_across_domains(pbias_dams, sim_dir, "mad_pbias_rel_cal.pdf", pbias_dams$name, pbias_dams$rel_cal, "Dam", "PBIAS", c(-50, 50))
  
  # Combine
  system(paste("convert -density 150 $(ls -rt ", sim_dir,"/mad_*_scc_cal.pdf) ", sim_dir,"/mad_scc_cal.pdf", sep = ""))
  system(paste("convert -density 150 $(ls -rt ", sim_dir,"/mad_*_scc_val.pdf) ", sim_dir,"/mad_scc_val.pdf", sep = ""))
  system(paste("convert -density 150 $(ls -rt ", sim_dir,"/mad_*_rel_cal.pdf) ", sim_dir,"/mad_rel_cal.pdf", sep = ""))
  system(paste("convert -density 150 $(ls -rt ", sim_dir,"/mad_*_rel_val.pdf) ", sim_dir,"/mad_rel_val.pdf", sep = ""))
  # Remove individual files
  system(paste("rm ", sim_dir,"/mad_*_scc*.pdf", sep = ""))
  system(paste("rm ", sim_dir,"/mad_*_rel*.pdf", sep = ""))
  
  
  # ==========================
  # Diff Metrics across dams (DMAD) plots
  # ==========================
  
  # Calibration Diffs
  
  # logNSE
  plot_metrics_across_domains(diff_lognse_dams, sim_dir, "dmad_lognse_cal.pdf", diff_lognse_dams$name, diff_lognse_dams$cal_diff, "Dam", expression(paste(Delta, " log NSE")), c(-1, 1))
  # NSE
  plot_metrics_across_domains(diff_nse_dams, sim_dir, "dmad_nse_cal.pdf", diff_nse_dams$name, diff_nse_dams$cal_diff, "Dam", expression(paste(Delta, " NSE")), c(-1, 1))
  # KGE
  plot_metrics_across_domains(diff_kge_dams, sim_dir, "dmad_kge_cal.pdf", diff_kge_dams$name, diff_kge_dams$cal_diff, "Dam", expression(paste(Delta, " KGE")), c(-1, 1))
  # Gamma
  plot_metrics_across_domains(diff_gam_dams, sim_dir, "dmad_gamma_cal.pdf", diff_gam_dams$name, diff_gam_dams$cal_diff, "Dam", expression(paste(Delta, gamma, sep = " ")), c(-0.5, 0.5))
  # Beta
  plot_metrics_across_domains(diff_bet_dams, sim_dir, "dmad_beta_cal.pdf", diff_bet_dams$name, diff_bet_dams$cal_diff, "Dam", expression(paste(Delta, beta, sep = " ")), c(-2, 2))
  # Alpha
  plot_metrics_across_domains(diff_alp_dams, sim_dir, "dmad_alpha_cal.pdf", diff_alp_dams$name, diff_alp_dams$cal_diff, "Dam", expression(paste(Delta, alpha, sep = " ")), c(-2, 2))
  # PBIAS
  plot_metrics_across_domains(diff_pbias_dams, sim_dir, "dmad_pbias_cal.pdf", diff_pbias_dams$name, diff_pbias_dams$cal_diff, "Dam", expression(paste(Delta, " PBIAS")), c(-50, 50))
  
  
  # Validation Diffs
  
  # logNSE
  plot_metrics_across_domains(diff_lognse_dams, sim_dir, "dmad_lognse_val.pdf", diff_lognse_dams$name, diff_lognse_dams$val_diff, "Dam", expression(paste(Delta, " log NSE")), c(-1, 1))
  # NSE
  plot_metrics_across_domains(diff_nse_dams, sim_dir, "dmad_nse_val.pdf", diff_nse_dams$name, diff_nse_dams$val_diff, "Dam", expression(paste(Delta, " NSE")), c(-1, 1))
  # KGE
  plot_metrics_across_domains(diff_kge_dams, sim_dir, "dmad_kge_val.pdf", diff_kge_dams$name, diff_kge_dams$val_diff, "Dam", expression(paste(Delta, " KGE")), c(-1, 1))
  # Gamma
  plot_metrics_across_domains(diff_gam_dams, sim_dir, "dmad_gamma_val.pdf", diff_gam_dams$name, diff_gam_dams$val_diff, "Dam", expression(paste(Delta, gamma, sep = " ")), c(-0.5, 0.5))
  # Beta
  plot_metrics_across_domains(diff_bet_dams, sim_dir, "dmad_beta_val.pdf", diff_bet_dams$name, diff_bet_dams$val_diff, "Dam", expression(paste(Delta, beta, sep = " ")), c(-2, 2))
  # Alpha
  plot_metrics_across_domains(diff_alp_dams, sim_dir, "dmad_alpha_val.pdf", diff_alp_dams$name, diff_alp_dams$val_diff, "Dam", expression(paste(Delta, alpha, sep = " ")), c(-2, 2))
  # PBIAS
  plot_metrics_across_domains(diff_pbias_dams, sim_dir, "dmad_pbias_val.pdf", diff_pbias_dams$name, diff_pbias_dams$val_diff, "Dam", expression(paste(Delta, " PBIAS")), c(-50, 50))
  
  # Combine
  system(paste("convert -density 150 $(ls -rt ", sim_dir,"/dmad_*_cal.pdf) ", sim_dir,"/dmad_cal.pdf", sep = ""))
  system(paste("convert -density 150 $(ls -rt ", sim_dir,"/dmad_*_val.pdf) ", sim_dir,"/dmad_val.pdf", sep = ""))
  # Remove individual files
  system(paste("rm ", sim_dir,"/dmad_*_*.pdf", sep = ""))
  
  
  
  # # ==========================
  # # Met Check Plot
  # # ==========================
  # main <- ggplot() +
  #   # Column pairs
  #   geom_bar(data = met_matrix_melt, aes( x= c(rep(1:ndomains,2)), y = value, fill = as.factor(variable) ),
  #            position = "dodge", width = 0.5, stat = "identity") +
  #   # KGE
  #   geom_point(data = data.frame(kge_matrix$SCC*met_upper_limit), aes( x= c(1:ndomains), y = kge_matrix$SCC*met_upper_limit), color = "black", alpha = 1, size = 1) +
  # 
  #   scale_fill_manual(values = clrs2,
  #                     labels = c("average annual lake evaporation (mm)",
  #                                "average annual lake precipitation (mm)")) +
  # 
  #   # ggtitle(paste("# dams : ", ndomains_valid, " (", ndomains_shown_nse, ")", sep = "")) +
  # 
  #   theme(
  #     text=element_text(family = "Helvetica", colour = "black"),
  #     axis.ticks.length=unit(-0.2, "cm"),
  #     axis.ticks = element_line(colour = "black", size = 0.5),
  #     axis.text.x = element_text(size=5, colour = "black", angle = 90),
  #     axis.title.x = element_text(size=12, margin = margin(t = 10), colour = "black"),
  #     axis.text.y.left = element_text(size=12, margin = margin(r = 10), colour = "black"),
  #     axis.text.y.right = element_text(size=12, margin = margin(l = 10), colour = "black"),
  #     axis.title.y.left  = element_text(size=14, margin = margin(r = 15), colour = "black", hjust = c(0.5)),
  #     axis.title.y.right = element_text(size=14, margin = margin(l = 15), colour = "black", hjust = c(0.5)),
  #     plot.title = element_text(size = 12, colour = "blue"),
  #     panel.border = element_rect(colour = "black", fill=NA, size=1),
  #     panel.background = element_blank(),
  #     panel.grid.major = element_line(colour = alpha("black", 0.5), size=0.2, linetype = 3),
  #     legend.position = c(0.7, 0.85),
  #     legend.title = element_blank(),
  #     legend.background = element_blank()) +
  # 
  #   scale_x_discrete(name = "domainID", labels = letters[1:ndomains]) + #c(lut_data$station_id)) +
  # 
  #   scale_y_continuous(name = "average annual [mm]", breaks = c(seq(0,met_upper_limit,1000)), limits = c(0, met_upper_limit),
  #                      sec.axis = dup_axis(name = expression(paste(KGE[day], sep = "")), labels = c(seq(0,1,0.25))) )
  # 
  # # Output
  # ggsave(main, file=paste(sim_dir, fNameout_lake_evap , sep="/"), width = 12, height = 3, units = "in", dpi = 300)
  # 
  
  
} else { # forward_scalability


  # ==============================
  # Scalability RESOLVED Plot - 1
  # ==============================
  
  main <- ggplot() +
  
    # n resolved lines
    geom_line(data = nresolved_melt, aes( x= X1, y = value, color = factor(X2, levels = c("SCC", "D8")) ), 
              size = 0.5, linetype = 2, alpha = 0.4 ) +
    geom_point(data = nresolved_melt, aes( x= X1, y = value, color = factor(X2, levels = c("SCC", "D8")), 
                                           shape = factor(X2, levels = c("SCC", "D8"))  ), 
              size = 2, stroke = 1, fill = alpha("white", 0)) +
  
    scale_color_manual(values = (colors_nresolved),
                       labels = c("SCC", "D8")) +
    
    scale_shape_manual(values = c(19, 21),
                       labels = c("SCC", "D8")) +
  
  
    theme(
      text=element_text(family = "Helvetica", colour = "black"),
      axis.ticks.length=unit(-0.2, "cm"),
      axis.ticks = element_line(colour = "black", size = 0.5),
      axis.text.x = element_text(size=12, margin = margin(t = 5), colour = "black", vjust = c(0.5) ),
      axis.title.x = element_text(size=14, margin = margin(t = 15), colour = "black"),
      axis.title.y = element_text(size=12, margin = margin(r = 10), colour = "black"),
      # axis.text.y.left = element_text(size=12, margin = margin(r = 10), colour = "black"),
      axis.text.y.left = element_blank(),
      axis.text.y.right = element_text(size=12, margin = margin(l = 10), colour = "black"),
      axis.title.y.left  = element_text(size=14, margin = margin(r = 15), colour = "black", hjust = c(0.5)),
      axis.title.y.right = element_blank(),
      plot.title = element_text(size = 12, colour = "blue"),
      panel.border = element_rect(colour = "black", fill=NA, size=1),
      panel.background = element_blank(),
      panel.grid.major = element_line(colour = alpha("black", 0.5), size=0.2, linetype = 3),
      legend.position = c(0.3, 0.3),
      legend.title = element_blank(),
      legend.key = element_blank(),
      legend.key.height = unit(0.8, "cm"),
      legend.key.width = unit(1.2, "cm"),
      legend.text = element_text(size=12, colour = "black"),
      legend.background = element_rect(fill=alpha("white",0.75))) +
  
    scale_x_continuous(name = "model resolution [ degrees ]", breaks = c(seq(1,7)),
                       labels = c(expression(paste(2^{-6}, sep = "")),
                                  expression(paste(2^{-5}, sep = "")),
                                  expression(paste(2^{-4}, sep = "")),
                                  expression(paste(2^{-3}, sep = "")),
                                  expression(paste(2^{-2}, sep = "")),
                                  expression(paste(2^{-1}, sep = "")),
                                  expression(paste(2^{0}, sep = ""))) ) +
                       # labels = rev(resnames) ) +
  
                       
    scale_y_continuous(name = "\n reservoirs resolved [ % ]",
                       sec.axis = dup_axis())
  
  # Output
  ggsave(main, file=paste(sim_dir, fNameout_nresolved , sep="/"), width = 5, height = 4, units = "in", dpi = 300)
  
  
  # ==============================
  # Scalability RESOLVED Plot - 2
  # ==============================
  
  main <- ggplot() +
    
    # n resolved lines
    geom_line(data = saresolved_melt, aes( x= X1, y = value, color = factor(X2, levels = c("SCC", "D8")) ), 
              size = 0.5, linetype = 2, alpha = 0.4 ) +
    geom_point(data = saresolved_melt, aes( x= X1, y = value, color = factor(X2, levels = c("SCC", "D8")), 
                                           shape = factor(X2, levels = c("SCC", "D8"))  ), 
               size = 2, stroke = 1, fill = alpha("white", 0)) +
    
    scale_color_manual(values = (colors_nresolved),
                       labels = c("SCC", "D8")) +
    
    scale_shape_manual(values = c(19, 21),
                       labels = c("SCC", "D8")) +
    
    
    theme(
      text=element_text(family = "Helvetica", colour = "black"),
      axis.ticks.length=unit(-0.2, "cm"),
      axis.ticks = element_line(colour = "black", size = 0.5),
      axis.text.x = element_text(size=12, margin = margin(t = 5), colour = "black", vjust = c(0.5) ),
      axis.title.x = element_text(size=14, margin = margin(t = 15), colour = "black"),
      axis.title.y = element_text(size=12, margin = margin(r = 10), colour = "black"),
      # axis.text.y.left = element_text(size=12, margin = margin(r = 10), colour = "black"),
      axis.text.y.left = element_blank(),
      axis.text.y.right = element_text(size=12, margin = margin(l = 10), colour = "black"),
      axis.title.y.left  = element_text(size=14, margin = margin(r = 15), colour = "black", hjust = c(0.5)),
      axis.title.y.right = element_blank(),
      plot.title = element_text(size = 12, colour = "blue"),
      panel.border = element_rect(colour = "black", fill=NA, size=1),
      panel.background = element_blank(),
      panel.grid.major = element_line(colour = alpha("black", 0.5), size=0.2, linetype = 3),
      legend.position = c(0.3, 0.7),
      legend.title = element_blank(),
      legend.key = element_blank(),
      legend.key.height = unit(0.8, "cm"),
      legend.key.width = unit(1.2, "cm"),
      legend.text = element_text(size=12, colour = "black"),
      legend.background = element_rect(fill=alpha("white",0.75))) +
    
    scale_x_continuous(name = "model resolution [ degrees ]", breaks = c(seq(1,7)),
                       labels = c(expression(paste(2^{-6}, sep = "")),
                                  expression(paste(2^{-5}, sep = "")),
                                  expression(paste(2^{-4}, sep = "")),
                                  expression(paste(2^{-3}, sep = "")),
                                  expression(paste(2^{-2}, sep = "")),
                                  expression(paste(2^{-1}, sep = "")),
                                  expression(paste(2^{0}, sep = ""))) ) +
                       # labels = rev(resnames) ) +
    
    scale_y_continuous(name = expression(atop("median surface area of", "reservoirs resolved [ "*km^2*" ]")),
                       sec.axis = dup_axis())
  
  # Output
  ggsave(main, file=paste(sim_dir, fNameout_saresolved , sep="/"), width = 5, height = 4, units = "in", dpi = 300)
  
  
  
  # ====================================
  # KGE ensemble Box Plots
  # ====================================
  
  main <- ggplot() + 
    # geom_boxplot(data = kge_ensemble_melt, 
     # geom_boxplot(data = kge_ensemble_stnneardam_melt,
    geom_boxplot(data = kge_matrix_stnneardam_sel_melt,
                 aes(x = as.factor(X2), y = value, color = factor(X1, levels = c("SCC", "D8")), 
                     fill = factor(X1, levels = c("SCC", "D8")) ), alpha = 0.6, varwidth = TRUE, na.rm = TRUE) + 
    
    # geom_line(data = kge_matrix_stnneardam_sel_median_melt[order(kge_matrix_stnneardam_sel_median_melt$X1, decreasing = TRUE),], 
    #           # aes( x= as.factor(X2), y = value, color = factor(X1, levels = c("SCC", "D8")) ), size = 1, linetype = 2, alpha = 0.4 ) +
    #           aes( x= rep(c(rev(seq(1:5))),2), y = value, color = factor(X1, levels = c("SCC", "D8")) ), size = 0.5, linetype = 1 ) +
    
    scale_color_manual(values = colors_nresolved,
                       labels = c("SCC", "D8")) +
    
    scale_fill_manual(values = colors_nresolved,
                      labels = c("SCC", "D8")) +
    
    scale_alpha_manual(values = c(0.5, 0.6),
                       labels = c("SCC", "D8")) +
    
    labs(title = paste("c.a. at station / c.a. at dam < ", near_far_stn_threshold, sep = ""), 
         subtitle = paste("no. of dams : ", n_kge_matrix_stnneardam_sel, sep = "")) +
    
    
    theme(
      text=element_text(family = "Helvetica", colour = "black"),
      axis.ticks.length=unit(-0.2, "cm"), 
      axis.ticks = element_line(colour = "black", size = 0.5),
      axis.text.x = element_text(size=12, margin = margin(t = 10), colour = "black"), 
      axis.title.x = element_text(size=14, margin = margin(t = 20), colour = "black"),
      axis.text.y.left = element_text(size=12, margin = margin(r = 10), colour = "black"), 
      axis.text.y.right = element_text(size=12, margin = margin(l = 10), colour = "black"), 
      axis.title.y.left  = element_text(size=14, margin = margin(r = 10), colour = "black", hjust = c(0.5)), 
      axis.title.y.right = element_blank(),
      plot.title = element_text(size = 14, colour = "black"),
      plot.subtitle = element_text(size = 14, colour = "blue", margin = margin(b = 40)),
      panel.border = element_rect(colour = "black", fill=NA, size=1),
      panel.background = element_blank(),
      panel.grid.major = element_line(colour = alpha("black", 0.5), size=0.2, linetype = 3),
      legend.position = c(0.7, 1.1),
      legend.title = element_blank(),
      legend.text = element_text(size = 12),
      legend.key.height = unit(1, "cm"),
      legend.key.width = unit(0.7, "cm"),
      legend.key = element_blank(),
      legend.direction = "horizontal",
      legend.background = element_blank()) +
    
    scale_x_discrete(name = "Model resolutions [ degrees ]", 
                     labels = c(expression(paste(2^{-4}, sep = "")),
                                expression(paste(2^{-3}, sep = "")),
                                expression(paste(2^{-2}, sep = ""))) ) +
                     # labels = rev(resnames_sel)) +
  
    # neve use limits in scale_y_* instruction for boxplots
    scale_y_continuous(name = expression(paste(KGE[day], sep = "")) , 
                       breaks = seq(metrics_ens_lower_limit,1,0.5), labels = c(seq(metrics_ens_lower_limit,1,0.5)),
                       sec.axis = dup_axis(name ="")) +
  
    coord_cartesian(ylim = c(metrics_ens_lower_limit, metrics_ens_upper_limit))
  
  # Output
  ggsave(main, file=paste(sim_dir, fNameout_kge_ens_boxplot_stnneardam, sep="/"), width = 4, height = 4, units = "in", dpi = 300)
  
  
  main <- ggplot() + 
    # geom_boxplot(data = kge_ensemble_melt, 
    # geom_boxplot(data = kge_ensemble_stnfardam_melt,
    geom_boxplot(data = kge_matrix_stnfardam_sel_melt,
                 aes(x = as.factor(X2), y = value, color = factor(X1, levels = c("SCC", "D8")), 
                     fill = factor(X1, levels = c("SCC", "D8")) ), alpha = 0.6, varwidth = TRUE, na.rm = TRUE) + 
    
    scale_color_manual(values = colors_nresolved,
                       labels = c("SCC", "D8")) +
    
    scale_fill_manual(values = colors_nresolved,
                      labels = c("SCC", "D8")) +
    
    scale_alpha_manual(values = c(0.5, 0.6),
                       labels = c("SCC", "D8")) +
    
    labs(title = paste("c.a. at station / c.a. at dam >= ", near_far_stn_threshold, sep = ""), 
         subtitle = paste("no. of dams : ", n_kge_matrix_stnfardam_sel, sep = "")) +
    
    
    theme(
      text=element_text(family = "Helvetica", colour = "black"),
      axis.ticks.length=unit(-0.2, "cm"), 
      axis.ticks = element_line(colour = "black", size = 0.5),
      axis.text.x = element_text(size=12, margin = margin(t = 10), colour = "black"), 
      axis.title.x = element_text(size=14, margin = margin(t = 20), colour = "black"),
      axis.text.y.left = element_text(size=12, margin = margin(r = 10), colour = "black"), 
      axis.text.y.right = element_text(size=12, margin = margin(l = 10), colour = "black"), 
      axis.title.y.left  = element_text(size=14, margin = margin(r = 10), colour = "black", hjust = c(0.5)), 
      axis.title.y.right = element_blank(),
      plot.title = element_text(size = 14, colour = "black"),
      plot.subtitle = element_text(size = 14, colour = "blue", margin = margin(b = 40)),
      panel.border = element_rect(colour = "black", fill=NA, size=1),
      panel.background = element_blank(),
      panel.grid.major = element_line(colour = alpha("black", 0.5), size=0.2, linetype = 3),
      legend.position = c(0.7, 1.1),
      legend.title = element_blank(),
      legend.text = element_text(size = 12),
      legend.key.height = unit(1, "cm"),
      legend.key.width = unit(0.7, "cm"),
      legend.key = element_blank(),
      legend.direction = "horizontal",
      legend.background = element_blank()) +
    
    scale_x_discrete(name = "Model resolutions [ degrees ]", 
                     labels = c(expression(paste(2^{-4}, sep = "")),
                                expression(paste(2^{-3}, sep = "")),
                                expression(paste(2^{-2}, sep = ""))) ) +
                     # labels = rev(resnames_sel)) +
    
    # neve use limits in scale_y_* instruction for boxplots
    scale_y_continuous(name = expression(paste(KGE[day], sep = "")) , 
                       breaks = seq(metrics_ens_lower_limit,1,0.5), labels = c(seq(metrics_ens_lower_limit,1,0.5)),
                       sec.axis = dup_axis(name ="")) +
    
    coord_cartesian(ylim = c(metrics_ens_lower_limit, metrics_ens_upper_limit))
  
  # Output
  ggsave(main, file=paste(sim_dir, fNameout_kge_ens_boxplot_stnfardam, sep="/"), width = 4, height = 4, units = "in", dpi = 300)
  
  
  
  
  # ==============================
  # Scalability metrics STABILITY
  # ==============================
  
  main <- ggplot() +
    
    # Chungju, SKorea
    geom_line(data = kge_chungju_melt, aes( x= rev(rep(c(seq(1,7)),2)), y = value, color = as.factor(X2) ), size = 1, linetype = 2, alpha = 0.4 ) +
    geom_point(data = kge_chungju_melt, aes( x= rev(rep(c(seq(1,7)),2)), y = value, color = as.factor(X2), shape = as.factor(X2)  ), 
               size = 2, stroke = 1, fill = alpha("white", 0)) +
    
    scale_color_manual(values = (colors_nresolved),
                       labels = c("SCC", "D8")) +
    
    scale_shape_manual(values = c(19, 21),
                       labels = c("SCC", "D8")) +
    
    labs(title = "Chungju Reservoir, South Korea", subtitle = paste("c.a. at station / c.a. at dam : ", round(lut_data$ds_stn_cr1[9], 2), sep = "")) +
    
    theme(
      text=element_text(family = "Helvetica", colour = "black"),
      axis.ticks.length=unit(-0.2, "cm"),
      axis.ticks = element_line(colour = "black", size = 0.5),
      axis.text.x = element_text(size=12, margin = margin(t = 5), colour = "black", vjust = c(0.5) ),
      axis.title.x = element_text(size=14, margin = margin(t = 15), colour = "black"),
      axis.title.y = element_text(size=12, margin = margin(r = 10), colour = "black"),
      axis.text.y.left = element_text(size=12, margin = margin(r = 10), colour = "black"),
      axis.text.y.right = element_text(size=12, margin = margin(l = 10), colour = "black"),
      axis.title.y.left  = element_text(size=14, margin = margin(r = 10), colour = "black", hjust = c(0.5)),
      axis.title.y.right = element_blank(),
      plot.title = element_text(size = 12, colour = "blue"),
      panel.border = element_rect(colour = "black", fill=NA, size=1),
      panel.background = element_blank(),
      panel.grid.major = element_line(colour = alpha("black", 0.5), size=0.2, linetype = 3),
      legend.position = c(0.3, 0.3),
      legend.title = element_blank(),
      legend.key = element_blank(),
      legend.key.height = unit(0.8, "cm"),
      legend.key.width = unit(1.2, "cm"),
      legend.text = element_text(size=12, colour = "black"),
      legend.background = element_rect(fill=alpha("white",0.75))) +
    
    scale_x_continuous(name = "model resolution [ degrees ]", breaks = c(seq(1,7)),
                       labels = c(expression(paste(2^{-6}, sep = "")),
                                  expression(paste(2^{-5}, sep = "")),
                                  expression(paste(2^{-4}, sep = "")),
                                  expression(paste(2^{-3}, sep = "")),
                                  expression(paste(2^{-2}, sep = "")),
                                  expression(paste(2^{-1}, sep = "")),
                                  expression(paste(2^{0}, sep = ""))) ) +
    
    scale_y_continuous(name = expression(paste(KGE[day], sep = "")) , limits = c(metrics_stability_lower_limit, 1),
                       breaks = seq(metrics_stability_lower_limit,1,0.2), labels = c(seq(metrics_stability_lower_limit,1,0.2)),
                       sec.axis = dup_axis(name =""))
  
  # Output
  ggsave(main, file=paste(sim_dir, fNameout_stability_caratio_low , sep="/"), width = 4, height = 4, units = "in", dpi = 300)
  
  
  
  main <- ggplot() +
    
    # Tres Marias, Brazil
    geom_line(data = kge_tresmarias_melt, aes( x= rev(rep(c(seq(1,7)),2)), y = value, color = as.factor(X2) ), size = 1, linetype = 2, alpha = 0.4 ) +
    geom_point(data = kge_tresmarias_melt, aes( x= rev(rep(c(seq(1,7)),2)), y = value, color = as.factor(X2), shape = as.factor(X2)  ), 
               size = 2, stroke = 1, fill = alpha("white", 0)) +
    
    scale_color_manual(values = (colors_nresolved),
                       labels = c("SCC", "D8")) +
    
    scale_shape_manual(values = c(19, 21),
                       labels = c("SCC", "D8")) +
    
    labs(title = "Trés Marias Reservoir, Brazil", subtitle = paste("c.a. at station / c.a. at dam : ", round(lut_data$ds_stn_cr1[77], 2), sep = "")) +
    
    
    theme(
      text=element_text(family = "Helvetica", colour = "black"),
      axis.ticks.length=unit(-0.2, "cm"),
      axis.ticks = element_line(colour = "black", size = 0.5),
      axis.text.x = element_text(size=12, margin = margin(t = 5), colour = "black", vjust = c(0.5) ),
      axis.title.x = element_text(size=14, margin = margin(t = 15), colour = "black"),
      axis.title.y = element_text(size=12, margin = margin(r = 10), colour = "black"),
      axis.text.y.left = element_text(size=12, margin = margin(r = 10), colour = "black"),
      axis.text.y.right = element_text(size=12, margin = margin(l = 10), colour = "black"),
      axis.title.y.left  = element_text(size=14, margin = margin(r = 10), colour = "black", hjust = c(0.5)),
      axis.title.y.right = element_blank(),
      plot.title = element_text(size = 12, colour = "blue"),
      panel.border = element_rect(colour = "black", fill=NA, size=1),
      panel.background = element_blank(),
      panel.grid.major = element_line(colour = alpha("black", 0.5), size=0.2, linetype = 3),
      legend.position = c(0.3, 0.3),
      legend.title = element_blank(),
      legend.key = element_blank(),
      legend.key.height = unit(0.8, "cm"),
      legend.key.width = unit(1.2, "cm"),
      legend.text = element_text(size=12, colour = "black"),
      legend.background = element_rect(fill=alpha("white",0.75))) +
    
    scale_x_continuous(name = "model resolution [ degrees ]", breaks = c(seq(1,7)),
                       labels = c(expression(paste(2^{-6}, sep = "")),
                                  expression(paste(2^{-5}, sep = "")),
                                  expression(paste(2^{-4}, sep = "")),
                                  expression(paste(2^{-3}, sep = "")),
                                  expression(paste(2^{-2}, sep = "")),
                                  expression(paste(2^{-1}, sep = "")),
                                  expression(paste(2^{0}, sep = ""))) ) +
    
    scale_y_continuous(name = expression(paste(KGE[day], sep = "")) , limits = c(metrics_stability_lower_limit, 1),
                       breaks = seq(metrics_stability_lower_limit,1,0.2), labels = c(seq(metrics_stability_lower_limit,1,0.2)),
                       sec.axis = dup_axis(name =""))
  
  # Output
  ggsave(main, file=paste(sim_dir, fNameout_stability_caratio_high , sep="/"), width = 4, height = 4, units = "in", dpi = 300)
  

  
  # # ==============================
  # # Scalability RESOLVED Plot - 2
  # # ==============================
  # 
  # main <- ggplot() +
  # 
  #   # most coarse resolving resolution
  #   geom_line(data = most_coarse_resolved_res_melt, aes( x= X1, y = value, color = factor(X2, levels = c("SCC", "D8")) ), size = 1 ) +
  # 
  #   scale_color_manual(values = rev(colors_nresolved),
  #                      labels = c("SCC", "D8")) +
  # 
  # 
  #   theme(
  #     text=element_text(family = "Helvetica", colour = "black"),
  #     axis.ticks.length=unit(-0.2, "cm"),
  #     axis.ticks = element_line(colour = "black", size = 0.5),
  #     axis.text.x = element_text(size=12, margin = margin(t = 10), colour = "black", angle = 90, hjust = c(1), vjust = c(0.5) ),
  #     axis.title.x = element_text(size=14, margin = margin(t = 10), colour = "black"),
  #     axis.title.y = element_text(size=12, margin = margin(r = 10), colour = "black"),
  #     axis.text.y.left = element_text(size=12, margin = margin(r = 10), colour = "black"),
  #     axis.text.y.right = element_text(size=12, margin = margin(l = 10), colour = "black"),
  #     axis.title.y.left  = element_text(size=14, margin = margin(r = 15), colour = "black", hjust = c(0.5)),
  #     axis.title.y.right = element_blank(),
  #     plot.title = element_text(size = 12, colour = "blue"),
  #     panel.border = element_rect(colour = "black", fill=NA, size=1),
  #     panel.background = element_blank(),
  #     panel.grid.major = element_line(colour = alpha("black", 0.5), size=0.2, linetype = 3),
  #     legend.position = c(0.3, 0.3),
  #     legend.title = element_blank(),
  #     legend.key = element_blank(),
  #     legend.text = element_text(size=12, colour = "black"),
  #     legend.background = element_blank()) +
  # 
  #   scale_x_continuous(name = "model resolution [ degrees ]", breaks = c(seq(1,7)),
  #                      labels = c(format(lapply(rev(seq(1:nresolutions)), function(x) 1/2^(x-1)), nsmall = 1)) ) +
  # 
  #   scale_y_continuous(name = "reservoirs resolved [%]",
  #                      sec.axis = dup_axis())
  # 
  # # Output
  # ggsave(main, file=paste(sim_dir, fNameout_nresolved , sep="/"), width = 4, height = 4, units = "in", dpi = 300)
  # 
  # 
  # 
  
  # # ====================================================
  # # CDF Plot - KGE Scalability
  # # ====================================================
  # 
  # main <- ggplot() +
  #   # CDFs
  #   stat_ecdf(data = kge_matrix_melt_spread_stnneardam, aes( x= value,
  #                                                 color = as.factor(paste(letters[X3], X2, sep = "")) ), 
  #             position = "identity", geom = "line", pad = FALSE, size = 0.5, alpha = 1, na.rm = TRUE) +
  #   # median
  #   geom_hline(yintercept = 0.5, color = "black", alpha = 0.3, size = 0.3, linetype = 1) +
  #   
  #   scale_color_manual(values = colors_metrics_spread) +#,
  #                      #labels = c(format(lapply(rev(seq(1:nresolutions)), function(x) 1/2^(x-1)), nsmall = 1)) ) +
  #   
  #   theme(
  #     text=element_text(family = "Helvetica", colour = "black"),
  #     axis.ticks.length=unit(-0.2, "cm"), 
  #     axis.ticks = element_line(colour = "black", size = 0.5),
  #     axis.text.x = element_text(size=12, margin = margin(t = 10), colour = "black"), 
  #     axis.title.x = element_text(size=14, margin = margin(t = 10), colour = "black"),
  #     axis.text.y.right = element_text(size=12, margin = margin(l = 10), colour = "black"), 
  #     axis.title.y.left  = element_text(size=14, margin = margin(r = 15), colour = "black", hjust = c(0.5)), 
  #     axis.title.y.right = element_blank(),
  #     plot.title = element_text(size = 12, colour = "blue"),
  #     panel.border = element_rect(colour = "black", fill=NA, size=1),
  #     panel.background = element_blank(),
  #     panel.grid.major = element_line(colour = alpha("black", 0.5), size=0.2, linetype = 3),
  #     legend.position = "none",
  #     # legend.position = c(0.33, 0.80),
  #     # legend.title = element_blank(),
  #     legend.background = element_blank()) +
  #   
  #   scale_x_continuous(name = expression(paste(KGE[day], sep = "")),
  #                      breaks = seq(metrics_lower_limit,1,0.2), labels = c(seq(metrics_lower_limit,1,0.2)),
  #                      sec.axis = dup_axis(name ="", labels = c())) +
  #   coord_cartesian(xlim = c(metrics_lower_limit, 1)) +
  #   
  #   scale_y_continuous(name = "CDF [-]", breaks = seq(0,1,0.2), labels = c(),
  #                      sec.axis = dup_axis(name ="", labels = c(seq(0,1,0.2)))) 
  # 
  # # Output
  # ggsave(main, file=paste(sim_dir, fNameout_cdf_kge_spread, sep="/"), width = 4, height = 4, units = "in", dpi = 300)
  # 
  # 
  # 
  
  
  
}
