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
library(dplyr)
library(foreach)    # parallelization
library(doParallel) # parallelization


# General control parameters
var <- "aET" # SM_Lall, aET
if (var == "aET"){
  factor <- 12
  yaxis <- "Domain average annual aET \nover the calibration period [mm/yr]"
}else if (var == "SM_Lall"){
  factor <- 1
  yaxis <- "Domain average soil moisture \nover the calibration period [mm/mm]"
}

sim_type = "forward"  # forward, forward_scalability
dir_name_B = "v6/mlm_2021_opti_v6_forward_predam_II" 
dir_name_C = "v6/mlm_2021_opti_v6_forward_default" 
dir_name_D = "v6/mlm_2021_opti_v6_forward_compensating" 

sim_dir = c(
            paste("/Users/shresthp/Nextcloud/Cloud/macbook/01_work/eve/data_from_eve/01_mlm_paper/ecflow_mlm2021/", dir_name_B, "/work/mhm", sep = ""),
            paste("/Users/shresthp/Nextcloud/Cloud/macbook/01_work/eve/data_from_eve/01_mlm_paper/ecflow_mlm2021/", dir_name_C, "/work/mhm", sep = ""),
            paste("/Users/shresthp/Nextcloud/Cloud/macbook/01_work/eve/data_from_eve/01_mlm_paper/ecflow_mlm2021/", dir_name_D, "/work/mhm", sep = "")
          )
nsimdir <- length(sim_dir)

lut_file= "/Users/shresthp/tmp/Win7/global_mlm/selection/atable_mlm_global_dam_selection_v1_tm_adj_v3.csv"

scc_dir   = "SCC" 
d8_dir   = "D8" 
rel_dir   = "RELEASE" 
cal_dir   = "cal" 
val_dir   = "val" 
fNamein_scc_mlm_fluxesstates = "mLM_Fluxes_States.nc"
fNamein_scc_mhm_fluxesstates = "mHM_Fluxes_States.nc"

fNameout_var_average_boxplot = paste(var, "_average_boxplot.pdf", sep = "")


# Graph parameters
metrics_interval = 0.5
metrics_ens_lower_limit = 0 #-0.5
metrics_ens_upper_limit = 1 # 1.5

near_far_stn_threshold  = 1.1 

clrs <- c("red", "blue")
labels <- c("no dam", "dam")


# ====================== DATA
# Read LUT file
lut_data <- read.delim(lut_file, sep = "," , header = TRUE )
ndomains = length(lut_data$station_id)

# initialize (3D)
NaData <- rep(NaN, ndomains*nsimdir*2)
var_avg_matrix <- array(NaData, c(ndomains, 3, 4))




# Get metrics from discharge files

for (idomain in 1: ndomains){
  
  # Get domain ID
  domainid = lut_data$station_id[idomain]
  
  
  for (isimdir in 1: nsimdir){
    
    # Get file paths
    path_1_cal =  paste(sim_dir[isimdir], domainid, scc_dir, "0p25/output", cal_dir, sep = "/")
    mhmfile_1_cal = paste(sim_dir[isimdir], domainid, scc_dir, "0p25/output", cal_dir, fNamein_scc_mhm_fluxesstates, sep = "/")
    path_1_val =  paste(sim_dir[isimdir], domainid, scc_dir, "0p25/output", val_dir, sep = "/")
    mhmfile_1_val = paste(sim_dir[isimdir], domainid, scc_dir, "0p25/output", val_dir, fNamein_scc_mhm_fluxesstates, sep = "/")
    if (sim_type == "forward_scalability"){
      path_2_cal =  paste(sim_dir[isimdir], domainid, d8_dir, "0p25/output", cal_dir, sep = "/")
      mhmfile_2_cal = paste(sim_dir[isimdir], domainid, d8_dir, "0p25/output", cal_dir, fNamein_scc_mhm_fluxesstates, sep = "/")
      path_2_val =  paste(sim_dir[isimdir], domainid, d8_dir, "0p25/output", val_dir, sep = "/")
      mhmfile_2_val = paste(sim_dir[isimdir], domainid, d8_dir, "0p25/output", val_dir, fNamein_scc_mhm_fluxesstates, sep = "/")
    } else {
      path_2_cal =  paste(sim_dir[isimdir], domainid, rel_dir, "0p25/output", cal_dir, sep = "/")
      mhmfile_2_cal = paste(sim_dir[isimdir], domainid, rel_dir, "0p25/output", cal_dir, fNamein_scc_mhm_fluxesstates, sep = "/")
      path_2_val =  paste(sim_dir[isimdir], domainid, rel_dir, "0p25/output", val_dir, sep = "/")
      mhmfile_2_val = paste(sim_dir[isimdir], domainid, rel_dir, "0p25/output", val_dir, fNamein_scc_mhm_fluxesstates, sep = "/")
    }
    
    
    
    #  ==  First set (SCC)
    
    # ---- Calibration
    # check whether the mhm FS files exist
    if (file.exists(mhmfile_1_cal)){
      # Read the netCDF file
      ncin <- nc_open(mhmfile_1_cal)
      # get VARIABLE
      var_3d <- ncvar_get(ncin, var)  # [lon, lat, time]
      # Read time attribute
      nctime <- ncvar_get(ncin,"time")
      nt <- dim(nctime)
      # Close the netCDF file
      nc_close(ncin)
      # Calculate and store basin average variable
      var_avg_matrix[idomain, isimdir, 1] <- mean(var_3d[,,], na.rm = TRUE) * factor
      # # Calculate and store basin average variable time series
      # # initialize
      # var_1d <- vector()
      # foreach (itime = 1:nt) %do% {
      #   # # MASK
      #   # data_3d[,,itime] <- ifelse(mask < 0, NA, data_3d[,,itime])
      #   # FLDMEAN
      #   var_1d[itime] <- mean(var_3d[,,itime], na.rm = TRUE)
      # }
    }
    
    # ---- Validation
    # check whether the mhm FS files exist
    if (file.exists(mhmfile_1_val)){
      # Read the netCDF file
      ncin <- nc_open(mhmfile_1_val)
      # get VARIABLE
      var_3d <- ncvar_get(ncin, var)  # [lon, lat, time]
      # Read time attribute
      nctime <- ncvar_get(ncin,"time")
      nt <- dim(nctime)
      # Close the netCDF file
      nc_close(ncin)
      # Calculate and store basin average variable
      var_avg_matrix[idomain, isimdir, 2] <- mean(var_3d[,,], na.rm = TRUE) * factor
    }
    
    
    # ==  Second Set (Release for Forward and D8 for Scalability Forward)
    
    # ---- Calibration
    # check whether the mhm FS files exist
    if (file.exists(mhmfile_2_cal)){
      # Read the netCDF file
      ncin <- nc_open(mhmfile_2_cal)
      # get VARIABLE
      var_3d <- ncvar_get(ncin, var)  # [lon, lat, time]
      # Read time attribute
      nctime <- ncvar_get(ncin,"time")
      nt <- dim(nctime)
      # Close the netCDF file
      nc_close(ncin)
      # Calculate and store basin average variable
      var_avg_matrix[idomain, isimdir, 3] <- mean(var_3d[,,], na.rm = TRUE) * factor
    }
    
    # ---- Validation
    # check whether the mhm FS files exist
    if (file.exists(mhmfile_2_val)){
      # Read the netCDF file
      ncin <- nc_open(mhmfile_2_val)
      # get VARIABLE
      var_3d <- ncvar_get(ncin, var)  # [lon, lat, time]
      # Read time attribute
      nctime <- ncvar_get(ncin,"time")
      nt <- dim(nctime)
      # Close the netCDF file
      nc_close(ncin)
      # Calculate and store basin average variable
      var_avg_matrix[idomain, isimdir, 4] <- mean(var_3d[,,], na.rm = TRUE) * factor
    }
    
    
  } # resolution loop
  
  print(paste(idomain, domainid, sep = " "))
}



# 3D to 2D
var_avg_matrix[is.nan(var_avg_matrix)] <- NA
var_avg_matrix_2d <- cbind(var_avg_matrix[,1,], var_avg_matrix[,2,], var_avg_matrix[,3,])

# consider only non NaNs (NAs)
var_avg_matrix_sel <- na.omit(var_avg_matrix_2d)

# MELT
# colnames
approach_names <- c("pre-dam", "default", "compensating")
# melt no dam (RELEASE, cal)
var_avg_nodam <- cbind(var_avg_matrix_sel[,3], var_avg_matrix_sel[,7], var_avg_matrix_sel[,11])
colnames(var_avg_nodam) <- approach_names
var_avg_nodam_melted <- melt(var_avg_nodam)
var_avg_nodam_melted$X1 <- "no dam"
# melt dam (SCC, cal)
var_avg_dam <- cbind(var_avg_matrix_sel[,1], var_avg_matrix_sel[,5], var_avg_matrix_sel[,9])
colnames(var_avg_dam) <- approach_names
var_avg_dam_melted <- melt(var_avg_dam)
var_avg_dam_melted$X1 <- "dam"
# combine melts
var_avg_melted <- rbind(var_avg_nodam_melted, var_avg_dam_melted)




# ====================== GRAPHS

# ==========================
# BoxPlot
# ==========================

plot_var_boxplot <- ggplot() + 
  
  geom_boxplot(data = var_avg_melted, 
               aes(x = factor(X2, levels = approach_names), 
                   y = value, 
                   color = factor(X1, levels = labels), 
                   fill = factor(X1, levels = labels) ), 
               alpha = 0.6, varwidth = TRUE) + 
  
  scale_color_manual(values = clrs,
                     labels = labels) +
  
  
  scale_fill_manual(values = clrs,
                    labels = labels) +
  
  
  scale_alpha_manual(values = c(0.5, 0.6),
                     labels = labels) +
  
  ggtitle("", subtitle = paste("dam count: ", dim(var_avg_matrix_sel)[1], sep = "")) +
  
  # labs(fill='RCP scenarios', color='RCP scenarios') + 
  
  theme(
    text=element_text(family = "Helvetica", colour = "black"),
    axis.ticks.length=unit(-0.2, "cm"), 
    axis.ticks = element_line(colour = "black", size = 0.5),
    axis.text.x = element_text(size=12, margin = margin(t = 10), colour = "black"), 
    axis.title.x = element_text(size=14, margin = margin(t = 30), colour = "black"),
    axis.text.y.left = element_text(size=12, margin = margin(r = 10), colour = "black"), 
    axis.text.y.right = element_text(size=12, margin = margin(l = 10), colour = "black"), 
    axis.title.y.left  = element_text(size=14, margin = margin(r = 15), colour = "black", hjust = c(0.5)), 
    axis.title.y.right = element_blank(),
    plot.subtitle = element_text(size = 12, colour = "blue", hjust = c(1)),
    panel.border = element_rect(colour = "black", fill=NA, size=1),
    panel.background = element_blank(),
    panel.grid.major = element_line(colour = alpha("black", 0.5), size=0.2, linetype = 3),
    legend.position = c(0.30, 0.15),
    legend.direction = "horizontal",
    legend.title = element_blank(),
    legend.text = element_text(size = 12),
    legend.key.height = unit(1, "cm"),
    legend.key.width = unit(0.7, "cm"),
    legend.key = element_blank(),
    legend.background = element_blank()) +
  
  scale_x_discrete(name = "Calibration approach", labels = approach_names ) +
  
  scale_y_continuous(name = yaxis, 
                     sec.axis = dup_axis(name ="")) +
  
  coord_cartesian(ylim = c(0,1500))

# Output
ggsave(plot_var_boxplot, file=paste(sim_dir[1], fNameout_var_average_boxplot, sep="/"), width = 6, height = 6, units = "in", dpi = 300)

