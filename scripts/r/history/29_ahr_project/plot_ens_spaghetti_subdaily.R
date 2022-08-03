#####################################################################################
##                   ----------------------------------------------------------------
## ==================== Ensemble Spaghetti Plot + medians, observation, issue dates
##                   ----------------------------------------------------------------
## --- Code developer: 
## ------------------  Pallav Kumar Shrestha pallav-kumar.shrestha@ufz.de ------
## ------------------  18 Jul 2021 ---------------------------------------------
##
## --- Mods: 
##          19 Jul 2021 - ribbons
##          12 Aug 2021 - return period flood calculations
##          13 Aug 2021 - hacked precipitation to secondary axis
##          13 Aug 2021 - soil moisture anomaly as third variable with hanging axis
##          13 Aug 2021 - observed instantaneous to daily calculations, legend as annotations
##          15 Aug 2021 - moved SMA to lowest position for a meteo-surface-subsurface order
##          17 Aug 2021 - adjusted for daily, masked SM and precipitation. Added climtologies - weekly, doy, moving window
##          18 Aug 2021 - second graph for 2021 showcasing evolution of sma vs precipitation
##          05 Sep 2021 - third graph for HICAM climate projections boxplot comparisons
##          13 Sep 2021 - added calculation of 24-h weights from era5 hourly precip 
##          30 Jul 2022 - clean version for subdaily refactoring. Find missing code blocks in daily version
#####################################################################################


# Open libraries/ packages
library(ggplot2)
library(ncdf4) 
library(xts) 
library(hydroTSM)
library(chron)
library(reshape) # for melt
library(scales)  # for pretty_breaks  
library(stringr) # for padding leading zeroes
source("~/git/gh/sabaile-paos/scripts/r/2022/01_phd_global_mlm/prepare_var_from_txt_input.R")
source("~/git/gh/sabaile-paos/scripts/r/2022/01_phd_global_mlm/prepare_var_from_mlm_fluxes_states.R")


# Paths and Files
#dataPath   = "./calibrated"
dataPath   = "./data/20220715/"
obsfile    = "./observed/Altenahr_hourly.txt" #"./observed/2718040300_Altenahr_Messdaten_Abfluss.csv" # latest only, processed from 15' instantaneous
obsfile_lt = "./observed/RP2718040300.txt" # long term daily data
# for 1: clean up the file using the "preprocess pre" code block provided in the masking script.
# for 2 and 3:  
#           a. mask using the masking script and mask provided in mask folder
#           b. further preprocess the spatial nc file using `cdo fldmean` to get point (spatial average) time series nc
# for 4: prepare the file using the readme.md provided

mask_germany="./mask/mask_processed_germany_extent.nc"
mask_ahr="./mask/mask_processed_ahr_extent.nc"

prefile_curr= "./dwd_precip/v1/pre_processed.nc" # 1
smfile_hist= "./baseline/v2/mHM_SM_Lall_1990_2019_masked_fldmean.nc" # 2
smfile_curr= "./baseline/v2/mHM_SM_Lall_2020_2021_masked_fldmean.nc" # 3
qfile_curr= "./baseline/v2/discharge_2020_2021.nc"

fNameOut   =  "mhm_flood_2021_ens_spaghetti_hourly.png"




# General control parameters
# Ensembles
ensStart   <- 0
ensEnd     <- 50
nEns       <- ensEnd - ensStart + 1
# Lead time
leadStart   <- 0
leadEnd     <- 4
nLead       <- leadEnd - leadStart + 1
# Forecast window
dStart     <- 10 #10
dEnd       <- 24 #24
nDays      <- dEnd - dStart
# Graph controls

  # Event Forecast
  nDays_prior <- 10
  ylimitgraph <- 350
  x_additional<- 0
#   
#   precip_scaling <- 1
#   precip_interval <- 50
#   precip_limit <- 100
#   
#   sm_graph_yintercept_start <- -150 #225
#   sm_graph_yintercept_end   <- -50 #275
#   sma_upper_limit <- 20
#   sma_lower_limit <- 0
#   
  clrs = c("#A0D613", "#025E04", "#3A6AFF", "#030580", "red", "white", "dodgerblue")
  alphas = c(0, 0.75)
#     #      light green, dark green, light blue, dark blue
#   
#   # 2021 
#   ylimitgraph_2021 <- 45
#   
#   precip_scaling_2021 <- 0.25
#   precip_interval_2021 <- 25
#   precip_limit_2021 <- 100
#   
#   sma_upper_limit_2021 <- 20
#   sma_lower_limit_2021 <- -5
#   sma_interval_2021 <- 5
#   
#   
# Others
misVal = -9999.0
year = 2021
month = 7


# Declare arrays to store data
df_ensembles_3d <- array(dim=c(nDays*24, nEns, nLead))
df_median_2d <- array(dim=c(nDays*24, nLead))
df_min_2d <- array(dim=c(nDays*24, nLead))
df_max_2d <- array(dim=c(nDays*24, nLead))






# ====================== OBSERVED DATA
# Read observed data (hourly)

obs_data_h <- prepare_var_from_txt_input(obsfile, "qobs_h")

# subset in time dimension for graph
obs_data_h_subset <- obs_data_h[paste(format(as.Date(paste(year, "/", month, "/", dStart-nDays_prior+1, sep = "")), "%Y-%m-%d"), "/", 
                             format(as.Date(paste(year, "/", month, "/", dEnd, sep = "")), "%Y-%m-%d"), sep = "")]
obs_data_h_subset_df <- data.matrix(as.numeric(obs_data_h_subset[,1]))
# melt!
obs_data_melted <- melt(obs_data_h_subset_df)



# >>> long term daily observations
obsdata_lt <- read.delim(obsfile_lt, sep = "", header = TRUE)
obsdata_lt[obsdata_lt == misVal] <- NA
obsdata_lt_dStart <- as.Date(paste(obsdata_lt[3,2],"-",obsdata_lt[3,3],"-",obsdata_lt[3,4],sep=""))  # Infering the start date
nobsdata_lt <- length(obsdata_lt[,1])
obsdata_lt_dEnd <- as.Date(paste(obsdata_lt[4,2],"-",obsdata_lt[4,3],"-",obsdata_lt[4,4],sep=""))  # Infering the end date
obsdata_lt_date <- seq.Date(obsdata_lt_dStart,obsdata_lt_dEnd, by= "days")
obsdata_lt <- as.matrix(obsdata_lt[5:nobsdata_lt,6])
obsdata_lt <- xts(as.numeric(obsdata_lt), order.by = obsdata_lt_date) # xts/ time series object created

# Long term average
obsdata_lt_ann_avg <- mean(obsdata_lt, na.rm = TRUE)
# Yearly daily max streamflow
obsdata_lt_ann_max <- as.matrix(daily2annual(obsdata_lt, FUN = max))




# ---------------------------
# FLOOD FREQUENCY ANALYSIS
# ---------------------------
# get ranks
obsdata_lt_ann_max_ranks <- length(obsdata_lt_ann_max) + 1 - rank(obsdata_lt_ann_max, ties.method = c("average"))
# get return periods
obsdata_lt_ann_max_T <- (length(obsdata_lt_ann_max) + 1)/obsdata_lt_ann_max_ranks

# fit a linear equation between Q and log(T)
fit_QT <- lm(obsdata_lt_ann_max~log(obsdata_lt_ann_max_T))
# estimate the return period floods with the equation
q_10y_T <- fit_QT$coefficients[1] + fit_QT$coefficients[2]*log(10)
q_100y_T <- fit_QT$coefficients[1] + fit_QT$coefficients[2]*log(100)
# more return periods for Table 1
q_2y_T <- fit_QT$coefficients[1] + fit_QT$coefficients[2]*log(2)
q_5y_T <- fit_QT$coefficients[1] + fit_QT$coefficients[2]*log(5)
q_20y_T <- fit_QT$coefficients[1] + fit_QT$coefficients[2]*log(20)







# ====================== FORECAST DATA


for (ilead in leadStart:leadEnd) { # Lead time loop
  
  for (iens in ensStart:ensEnd) { # Ensemble members loop
    
    
    # Parameters
    fName      = paste(dataPath, dStart+ilead ,"_", iens, ".nc", sep="")
    
    
    # Get XTS from the netCDF file
    qsim <- prepare_var_from_mlm_fluxes_states(fName, "Qsim_0271804030", F)
    
    
    # convert to dataframe
    df <- data.frame(qsim[1:(nDays*24)])
    colnames(df) <- (paste("ens ", iens, sep =""))
    
    
    if (iens == 0){
      # Initizlize dataframe
      df_ensembles <- data.frame(df)
    } else {
      # bind data
      df_ensembles <- cbind(df_ensembles, df)
    }
    
    
  } # Ensemble loop
  
  # --- Checkpoint: Dataframe with all ensemble members ready
  
  
  # convert to matrix
  df_ensembles <- data.matrix(df_ensembles)
  
  # save as 3D variable (ndays*24, nens, nlead)
  df_ensembles_3d[,,ilead+1] <- df_ensembles
  
  # save statistics of ensemble
  df_median <- apply(df_ensembles, 1, median)
  df_min <- apply(df_ensembles, 1, min)
  df_max <- apply(df_ensembles, 1, max)
  
  # save statistics as 2D variable (ndays*24, nlead)
  df_median_2d[,ilead+1] <- df_median
  df_min_2d[,ilead+1] <- df_min
  df_max_2d[,ilead+1] <- df_max
  
} # Lead time loop


# --- Checkpoint: Array with all ensemble members over all lead times ready; Arrays with ensemble stats ready


# ================
# Melt        - this helps to plot and group while plotting i.e. different colors for different lead times AND one spaghetti string for each member 
# ================
df_ensembles_3d_melted <- melt(df_ensembles_3d)
df_median_2d_melted <- melt(df_median_2d)
df_min_2d_melted <- melt(df_min_2d)
colnames(df_min_2d_melted) <- c("hour", "lead", "min")
df_max_2d_melted <- melt(df_max_2d)
colnames(df_max_2d_melted) <- c("hour", "lead", "max")
df_minmax_2d_melted <- cbind(df_min_2d_melted, df_max_2d_melted$max)
colnames(df_minmax_2d_melted) <- c("hour", "lead", "min", "max")

# --- Checkpoint: Arrays melted 



# Conditional edit for lead time
for (ilead in leadStart:leadEnd) { # Lead time loop
  
  ## All ensembles ##
  # edit for x-axis
  index <- df_ensembles_3d_melted$X3 == ilead + 1
  df_ensembles_3d_melted$X1[index] <- df_ensembles_3d_melted$X1[index] -1 + ilead * 24
  # (Var1 - 1) : as Var1 starts from 1 but should actually start from 0
  
  # edit for ensemble numbering
  df_ensembles_3d_melted$X2[index] <- df_ensembles_3d_melted$X2[index] + ilead * nEns
  
  
  ## Ensemble median ##
  # edit for x-axis
  index <- df_median_2d_melted$X2 == ilead + 1
  df_median_2d_melted$X1[index] <- df_median_2d_melted$X1[index] -1 + ilead * 24
  
  
  ## Ensemble min max ##
  # edit for x-axis
  index <- df_minmax_2d_melted$lead == ilead + 1
  df_minmax_2d_melted$hour[index] <- df_minmax_2d_melted$hour[index] -1 + ilead * 24
  df_min_2d_melted$hour[index] <- df_min_2d_melted$hour[index] -1 + ilead * 24
  df_max_2d_melted$hour[index] <- df_max_2d_melted$hour[index] -1 + ilead * 24
  
}

# --- Checkpoint: Melted arrays adjusted 




# ====================== GRAPH

# Prepare x-axis 
dayBreaks <- c(seq(-nDays_prior*24, (nDays + nLead - 1)*24 , 5*24))
dayLabels <- c(seq(dStart - nDays_prior, dEnd + nLead, 5))
# dayLabels <- c("", dayLabels[2:length(dayLabels)])



# ==========================
# JULY Plot
# ==========================


main <- ggplot() + 
  # x axis
  geom_hline(yintercept = 0, linetype = 1, size = 0.25, color = "black", show.legend = TRUE) +
  
  # 10-yr return period flood - horizontal line
  geom_hline(yintercept = q_10y_T, linetype = 5, size = 0.4, color = "black", show.legend = TRUE, alpha = 0.5) +
  # 100-yr return period flood - horizontal line
  geom_hline(yintercept = q_100y_T, linetype = 2, size = 0.4, color = "black", show.legend = TRUE, alpha = 0.5) +
  
  # # issue days translucent background
  # annotate("rect", xmin =-1, xmax =17,  ymin = 40,  ymax = 200,  alpha = 0.7, fill = "white") +
  # issue days - vertical lines
  geom_vline(xintercept = 0, linetype = 1, color = clrs[1], size = 0.5, alpha = 0.5) +
  geom_vline(xintercept = 1*24, linetype = 1, color = clrs[2], size = 0.5, alpha = 0.5) +
  geom_vline(xintercept = 2*24, linetype = 1, color = clrs[3], size = 0.5, alpha = 0.5) +
  geom_vline(xintercept = 3*24, linetype = 1, color = clrs[4], size = 0.5, alpha = 0.5) +
  geom_vline(xintercept = 4*24, linetype = 1, color = clrs[5], size = 0.5, alpha = 0.5) +
  
  
  # observed
  geom_line(data = obs_data_melted, aes( x = X1-(nDays_prior-1)*24, y = value), 
            color = "red", linetype = 1, size = 0.5, alpha = 1) + 
  
  # ensemble bands (only fill, no bounds)
  geom_ribbon(data = df_minmax_2d_melted, aes( x = hour, ymin = min, ymax = max,  group = lead, fill = as.factor(lead) ), linetype = 1, size = 0.3, alpha = 0.2) +
  # each ensemble
  geom_line(data = df_ensembles_3d_melted, aes( x = X1, y = value, group = X2, color = as.factor(X3)), linetype = 1, size = 0.1, alpha = 0.2) +
  # max (upper bound for ensemble bands)
  geom_line(data = df_max_2d_melted, aes( x = hour, y = max, group = lead, color = as.factor(lead)), linetype = 1, size = 0.3, alpha = 0.5) +
  # medians
  geom_line(data = df_median_2d_melted, aes( x = X1, y = value, group = X2, color = as.factor(X2) ), linetype = 2, size = 0.5, alpha = 0.5) +
  
  
  scale_color_manual(values = clrs,
                     labels = c("10 July issue forecasts", 
                                "11 July issue forecasts", 
                                "12 July issue forecasts", 
                                "13 July issue forecasts")) +
  
  
  scale_fill_manual(values = clrs,
                    labels = c("10 July issue forecasts", 
                               "11 July issue forecasts", 
                               "12 July issue forecasts", 
                               "13 July issue forecasts")) +
  
  scale_alpha_manual(values = alphas) +
  guides(color=FALSE) + # exclude fill aesthetics in legend
  
  # annotations
  # Issue days lines
  annotate("text", x = -0.2*24,  y = 450,  cex = 2, label = '5 days in advance', colour = "black", angle = 90) +
  annotate("text", x = 0.8*24,   y = 450,  cex = 2, label = '4 days in advance', colour = "black", angle = 90) +
  annotate("text", x = 1.8*24,   y = 450,  cex = 2, label = '3 days in advance', colour = "black", angle = 90) +
  annotate("text", x = 2.8*24,   y = 450,  cex = 2, label = '2 days in advance', colour = "black", angle = 90) +
  annotate("text", x = 3.8*24,   y = 450,  cex = 2, label = '1 day  in advance', colour = "black", angle = 90) +
  # Labels on the graph
  annotate("text", x =  0.9*24, y = 130,  cex = 2, label = '10 year return period flood', colour = "black") +
  annotate("text", x =  0.85*24, y = 205,  cex = 2, label = '100 year return period flood', colour = "black") +
  # # Legend using annotations
  # annotate("rect", xmin =7.5*24, xmax =17.6*24,  ymin = 200,  ymax = 500,  alpha = 0.95, fill = "white", linetype = 1, color = "black") + # translucent background
  # annotate("text", x = 12.5*24,   y = 190,  cex = 2, label = format('forecast ensemble', width = 45, justify = "left"), colour = "black") +
  # annotate("rect", xmin =  11*24, xmax =  12*24,  ymin = 475,  ymax = 495,  alpha = 0.2, fill = clrs[1]) + 
  # annotate("rect", xmin =  11*24, xmax =  12*24,  ymin = 180,  ymax = 190,  alpha = 0.2, fill = clrs[2]) + 
  # annotate("rect", xmin =12.5*24, xmax =13.5*24,  ymin = 195,  ymax = 205,  alpha = 0.2, fill = clrs[3]) + 
  # annotate("rect", xmin =12.5*24, xmax =13.5*24,  ymin = 180,  ymax = 190,  alpha = 0.2, fill = clrs[4]) + 
  # annotate("text", x = 18.5*24,   y = 160,  cex = 2, label = format('upper bounds of ensemble', width = 40, justify = "left"), colour = "black") +
  # annotate("segment", x =  11*24, xend =  12*24,  y = 165,  yend = 165,  alpha = 0.8, colour = clrs[1], size = 0.3) + 
  # annotate("segment", x =  11*24, xend =  12*24,  y = 155,  yend = 155,  alpha = 0.8, colour = clrs[2], size = 0.3) + 
  # annotate("segment", x =12.5*24, xend =13.5*24,  y = 165,  yend = 165,  alpha = 0.8, colour = clrs[3], size = 0.3) + 
  # annotate("segment", x =12.5*24, xend =13.5*24,  y = 155,  yend = 155,  alpha = 0.8, colour = clrs[4], size = 0.3) + 
  # annotate("text", x = 18.5*24,   y = 130,  cex = 2, label = format('individual ensemble forecasts', width = 40, justify = "left"), colour = "black") +
  # annotate("segment", x =  11*24, xend =  12*24,  y = 135,  yend = 135,  alpha = 1, colour = clrs[1], size = 0.1) + 
  # annotate("segment", x =  11*24, xend =  12*24,  y = 125,  yend = 125,  alpha = 1, colour = clrs[2], size = 0.1) + 
  # annotate("segment", x =12.5*24, xend =13.5*24,  y = 135,  yend = 135,  alpha = 1, colour = clrs[3], size = 0.1) + 
  # annotate("segment", x =12.5*24, xend =13.5*24,  y = 125,  yend = 125,  alpha = 1, colour = clrs[4], size = 0.1) + 
  # annotate("text", x = 18.5*24,   y = 100,  cex = 2, label = format('ensemble medians', width = 45, justify = "left"), colour = "black") +
  # annotate("segment", x =10.5*24, xend =12.0*24,  y = 105,  yend = 105,  alpha = 0.5, colour = clrs[1], size = 0.5, linetype = 2) + 
  # annotate("segment", x =10.5*24, xend =12.0*24,  y =  95,  yend =  95,  alpha = 0.5, colour = clrs[2], size = 0.5, linetype = 2) + 
  # annotate("segment", x =12.5*24, xend =14.0*24,  y = 105,  yend = 105,  alpha = 0.5, colour = clrs[3], size = 0.5, linetype = 2) + 
  # annotate("segment", x =12.5*24, xend =14.0*24,  y =  95,  yend =  95,  alpha = 0.5, colour = clrs[4], size = 0.5, linetype = 2) + 
  # annotate("text", x = 18.5*24,   y =  70,  cex = 2, label = format('observed', width = 51, justify = "left"), colour = "black") +
  # annotate("segment", x =   11*24, xend = 13.5*24,  y =  70,  yend =  70,  alpha = 0.5, colour = "red", size = 1, linetype = 1) + 
  # annotate("text", x = 18.5*24,   y =  45,  cex = 2, label = format('mHM', width = 51, justify = "left"), colour = "black") +
  # annotate("segment", x =   11*24, xend = 13.5*24,  y =  45,  yend =  45,  alpha = 0.5, colour = "black", size = 1, linetype = 1) + 
  
  ggtitle("HS2S Project Group, Computational Hydrosystems \n Helmholtz Centre for Environmental Research - UFZ") + 
  labs(subtitle = "\n Station:  Alten Ahr, 02718040300") +
  
  theme(
    text=element_text(family = "Helvetica", colour = "black"),
    axis.ticks.length=unit(-0.1, "cm"), 
    axis.ticks = element_line(colour = "black", size = 0.1),
    axis.text.x = element_text(size=8, margin = margin(t = 5), colour = "black"), 
    axis.title.x = element_text(size=10, margin = margin(t = 10), colour = "black"),
    axis.text.y.left  = element_text(size=8, margin = margin(r = 5), colour = "black"), 
    axis.text.y.right = element_text(size=8, margin = margin(l = 5), colour = "black"), 
    axis.title.y.left  = element_text(size=10, margin = margin(r = 5), colour = "black", hjust = c(0.5)), 
    axis.title.y.right = element_text(size=10, margin = margin(l = 10), colour = "black", hjust = 0), 
    panel.border = element_rect(colour = "black", fill=NA, size=0.5),
    panel.background = element_blank(),
    panel.grid = element_blank(),
    legend.position = 'none',
    plot.title = element_text(size = 4, hjust=c(1,1), margin = margin(b = -8)),
    plot.subtitle = element_text(size = 4, margin = margin(b = -8))) +
  
  scale_y_continuous(name = expression(paste("Streamflow (",m^{3},".",s^{-1},")", sep = ""))) +
                     
  scale_x_continuous(name = "Day of July, 2021", expand = c(0, 0), 
                     breaks = c(dayBreaks), labels = c(dayLabels), 
                     limits = c(-(nDays_prior-8)*24, (nDays + nLead - 8)*24), 
                       sec.axis = dup_axis(name ="", labels = c()) )

main

# Output
ggsave(main, file=paste(fNameOut, sep=""), width = 6, height = 3.5, units = "in", dpi = 300)




main <- ggplot() +
  
  # precipitation translucent background
  annotate("rect", xmin =-10, xmax =22,  ymin = ylimitgraph - precip_limit*precip_scaling,  ymax = ylimitgraph,  alpha = 0.1, fill = "black") +
  # dwd precipitation
  geom_bar(data = dwd_pre_cut_melted, aes( x = X1-nDays_prior , y = value, alpha = as.factor(X2)), fill = "dodgerblue",
           width = 0.5, linetype = 1, size = 0.5, stat = "identity", show.legend = FALSE, position = position_stack(reverse = TRUE)) +
  # mid line for precip
  geom_hline(yintercept = 0.5*(ylimitgraph - precip_limit*precip_scaling + ylimitgraph), linetype = 3, size = 0.1, color = "black", alpha = 0.7) +
  
  # mhm sma translucent background
  annotate("rect", xmin =-10, xmax =22,  ymin = sm_graph_yintercept_start,  ymax = sm_graph_yintercept_end,  alpha = 0.1, fill = "black") + 
  # mhm sma
  geom_point(data = mhm_sm_ano_cut_melted, aes( x = X1-nDays_prior, y = value), colour = "dodgerblue", size = 2, alpha = 0.75) +
  # mid line for sma
  geom_hline(yintercept = 0.5*(sm_graph_yintercept_start+sm_graph_yintercept_end), linetype = 3, size = 0.1, color = "black", alpha = 0.7) +
  
  
  
  # mHM Q forced with DWD
  geom_line(data = mhm_q_curr_cut_melted, aes( x = X1-nDays_prior, y = value), color = "black", linetype = 1, size = 1, alpha = 0.5) +
  
  
  
  scale_y_continuous(name = expression(paste("Streamflow (",m^{3},".",s^{-1},")", sep = "")), expand = c(0.03,0), limits = c(sm_graph_yintercept_start - 20, ylimitgraph),
                     breaks = c(sm_graph_yintercept_start, 0.5*(sm_graph_yintercept_start+sm_graph_yintercept_end), sm_graph_yintercept_end, 
                                seq(0,200,100),seq(ylimitgraph - precip_limit*precip_scaling, ylimitgraph, precip_interval*precip_scaling)), 
                     labels = c(rep("",3), seq(0,200,100),rep("",precip_limit/precip_interval+1)), 
                     sec.axis = sec_axis(~./precip_scaling, name = paste("Precipitation (mm)", "SM anomaly (%)", sep = "\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t"), 
                                         breaks = c(sm_graph_yintercept_start/precip_scaling, 0.5*(sm_graph_yintercept_start+sm_graph_yintercept_end)/precip_scaling, sm_graph_yintercept_end/precip_scaling, 
                                                    seq(ylimitgraph/precip_scaling - precip_limit, ylimitgraph/precip_scaling, precip_interval)), 
                                         labels = c(sma_lower_limit, 0.5*(sma_lower_limit+sma_upper_limit), sma_upper_limit, rev(seq(0,precip_limit,precip_interval)))) )
 
# Output
ggsave(main, file=paste(fNameOut, sep=""), width = 6, height = 4.5, units = "in", dpi = 300)
