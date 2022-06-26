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


# Paths and Files
dataPath   = "./calibrated"
obsfile    = "./observed/2718040300_Altenahr_Messdaten_Abfluss.csv" # latest only, processed from 15' instantaneous
obsfile_lt = "./observed/RP2718040300.txt" # long term daily data
# for 1: clean up the file using the "preprocess pre" code block provided in the masking script.
# for 2 and 3:  
#           a. mask using the masking script and mask provided in mask folder
#           b. further preprocess the spatial nc file using `cdo fldmean` to get point (spatial average) time series nc
# for 4: prepare the file using the readme.md provided

mask_germany="./mask/mask_processed_germany_extent.nc"
mask_ahr="./mask/mask_processed_ahr_extent.nc"

prefile_curr= "./dwd_precip/v1/pre_processed.nc" # 1
prefile_curr_hourly_lvl1= "./era5_hourly_precip/total_precipitation_2021_nn_latlon_lvl1.nc" # 4
prefile_curr_hourly_lvl5= "./era5_hourly_precip/total_precipitation_2021_nn_latlon_lvl5.nc" # 4
smfile_hist= "./baseline/v2/mHM_SM_Lall_1990_2019_masked_fldmean.nc" # 2
smfile_curr= "./baseline/v2/mHM_SM_Lall_2020_2021_masked_fldmean.nc" # 3
qfile_curr= "./baseline/v2/discharge_2020_2021.nc"
climproj_lut_file= "/Users/shresthp/Nextcloud/Cloud/macbook/01_work/Projects/05 MOSES/mhm_flood_2021/climproj/88_main_LUT_WL.txt"
climproj_fol= "/Users/shresthp/Nextcloud/Cloud/macbook/01_work/Projects/05 MOSES/mhm_flood_2021/climproj/q_routed"

fNameOut   =  "mhm_flood_2021_ens_spaghetti.png"
fNameOut_2021="mhm_flood_2021_pre_vs_sma_full_year.png"
fNameOut_climproj="mhm_flood_2021_climproj.png"


# General control parameters
# Ensembles
ensStart   <- 0
ensEnd     <- 50
nEns       <- ensEnd - ensStart + 1
# Lead time
leadStart   <- 0
leadEnd     <- 3
nLead       <- leadEnd - leadStart + 1
# Forecast window
dStart     <- 10
dEnd       <- 24
nDays      <- dEnd - dStart + 1
# Graph controls

  # Event Forecast
  nDays_prior <- 10
  ylimitgraph <- 350
  x_additional<- 4
  
  precip_scaling <- 1
  precip_interval <- 50
  precip_limit <- 100
  
  sm_graph_yintercept_start <- -150 #225
  sm_graph_yintercept_end   <- -50 #275
  sma_upper_limit <- 20
  sma_lower_limit <- 0
  
  clrs = c("#A0D613", "#025E04", "#3A6AFF", "#030580", "white", "dodgerblue")
  alphas = c(0, 0.75)
    #      light green, dark green, light blue, dark blue
  
  # 2021 
  ylimitgraph_2021 <- 45
  
  precip_scaling_2021 <- 0.25
  precip_interval_2021 <- 25
  precip_limit_2021 <- 100
  
  sma_upper_limit_2021 <- 20
  sma_lower_limit_2021 <- -5
  sma_interval_2021 <- 5
  
  
# Others
misVal = -9999.0
year = 2021
month = 7


# Declare arrays to store data
df_ensembles_3d <- array(dim=c(nDays, nEns, nLead))
df_median_2d <- array(dim=c(nDays, nLead))
df_min_2d <- array(dim=c(nDays, nLead))
df_max_2d <- array(dim=c(nDays, nLead))






# ====================== OBSERVED DATA
# Read observed data

# >>> latest daily data, processed from 15' instantaneous obsevations
obsdata_ins <- read.delim(obsfile, sep = c(";", ""), dec = ",", header = TRUE)
obsdata_ins <- cbind(as.character(obsdata_ins$Datum), as.character(obsdata_ins$Abfluss.in.m3.s) ) # get only the datatime and data columns
obsdata_ins[,2] <- as.numeric(gsub(",", ".", gsub(" ","",obsdata_ins[,2],  fixed = TRUE))) # convert the data column to numeric
# convert to xts
df_obs_ins <- xts(as.numeric(obsdata_ins[,2]), order.by = as.POSIXlt(as.character(obsdata_ins[,1]), format="%d.%m.%Y %H:%M"))
# convert 15' instantaneous obsevations to daily values
df_obs <- as.xts(subdaily2daily(df_obs_ins, FUN = mean, na.rm = TRUE))
# subset in time dimension for graph
df_obs_cut <- df_obs[paste(format(as.Date(paste(year, "/", month, "/", dStart-nDays_prior+1, sep = "")), "%Y-%m-%d"), "/", 
                             format(as.Date(paste(year, "/", month, "/", dEnd, sep = "")), "%Y-%m-%d"), sep = "")]
df_obs_cut <- data.matrix(as.numeric(df_obs_cut[,1]))
# melt!
df_obs_melted <- melt(df_obs_cut)



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



# ====================== The MASKS
# Read masks
# Read the netCDF file
ncin <- nc_open(mask_germany)
# get VARIABLE
mask_germany_extent<- ncvar_get(ncin,"mask")  # [lon, lat]
# Read the netCDF file
ncin <- nc_open(mask_ahr)
# get VARIABLE
mask_ahr_extent<- ncvar_get(ncin,"mask")  # [lon, lat]



# ====================== ERA5 hourly DATA
# Read ERA5 data
# Read the netCDF file
ncin <- nc_open(prefile_curr_hourly_lvl1)
# get VARIABLE
era5_h_pre_2d_lvl1<- ncvar_get(ncin,"tp")  # [lon, lat, time]
# Read the netCDF file
ncin <- nc_open(prefile_curr_hourly_lvl5)
# get VARIABLE
era5_h_pre_2d_lvl5<- ncvar_get(ncin,"tp")  # [lon, lat, time]
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

tchron <- chron(dates. = nctime/24, origin=c(tmonth, tday, tyear)) # nctime (hours)
tfinal <- as.POSIXct(tchron, tz = "GMT", origin=paste(tyear,tmonth,tday, sep = "-")) # nctime (hours)


# mask and fldmean
era5_h_pre_lvl1 <- vector()
era5_h_pre_lvl5 <- vector()
for (itime in 1:nt){
  # mask
  era5_h_pre_2d_lvl1[,,itime] <- ifelse(mask_ahr_extent < 0, NA, era5_h_pre_2d_lvl1[,,itime])
  era5_h_pre_2d_lvl5[,,itime] <- ifelse(mask_ahr_extent < 0, NA, era5_h_pre_2d_lvl5[,,itime])
  # fldmean
  era5_h_pre_lvl1[itime] <- mean(era5_h_pre_2d_lvl1[,,itime], na.rm = TRUE)
  era5_h_pre_lvl5[itime] <- mean(era5_h_pre_2d_lvl5[,,itime], na.rm = TRUE)
}
# dellocate immediately
#rm(era5_h_pre_2d_lvl1, era5_h_pre_2d_lvl5)
# convert to xts
era5_h_pre_lvl1 <- xts(as.numeric(era5_h_pre_lvl1), order.by = tfinal) # xts/ time series object created
colnames(era5_h_pre_lvl1) <- c("hourly")
era5_h_pre_lvl5 <- xts(as.numeric(era5_h_pre_lvl5), order.by = tfinal) # xts/ time series object created
colnames(era5_h_pre_lvl5) <- c("hourly")

# --  calculation of 24-h weights from era5 hourly precip 
# daily cummulative
era5_d_pre_lvl1 <- as.xts(subdaily2daily(era5_h_pre_lvl1, FUN=sum, na.rm = FALSE))
colnames(era5_d_pre_lvl1) <- c("daily")
era5_d_pre_lvl5 <- as.xts(subdaily2daily(era5_h_pre_lvl5, FUN=sum, na.rm = FALSE))
colnames(era5_d_pre_lvl5) <- c("daily")

# fractions (i.e. weights)
for (idate in as.character(index(era5_d_pre_lvl1))){
  era5_h_pre_lvl1$daily[date(index(era5_h_pre_lvl1)) == idate] <- era5_d_pre_lvl1[idate]
  era5_h_pre_lvl5$daily[date(index(era5_h_pre_lvl5)) == idate] <- era5_d_pre_lvl5[idate]
}
era5_h_pre_lvl1$weights <- era5_h_pre_lvl1$hourly / era5_h_pre_lvl1$daily
era5_h_pre_lvl5$weights <- era5_h_pre_lvl5$hourly / era5_h_pre_lvl5$daily

# printout weights
for (idate in as.character(index(era5_d_pre_lvl1))){ 
  
  print(idate)
  # level 1
  wts_vector <- era5_h_pre_lvl1$weights[date(index(era5_h_pre_lvl1)) == idate]
  if (length(wts_vector) == 24){
    wts_vector_line <- sprintf("%s, hweight_prec = %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f\n", 
                               idate,
                               wts_vector[1], wts_vector[2], wts_vector[3], 
                               wts_vector[4], wts_vector[5], wts_vector[6], 
                               wts_vector[7], wts_vector[8], wts_vector[9], 
                               wts_vector[10], wts_vector[11], wts_vector[12],
                               wts_vector[13], wts_vector[14], wts_vector[15], 
                               wts_vector[16], wts_vector[17], wts_vector[18], 
                               wts_vector[19], wts_vector[20], wts_vector[21], 
                               wts_vector[22], wts_vector[23], wts_vector[24])
    cat(wts_vector_line, file = "era5_hourly_precipitation_weights_level1_mhm_nml.txt", append = TRUE)
    
    # level 5
    wts_vector <- era5_h_pre_lvl5$weights[date(index(era5_h_pre_lvl5)) == idate]
    wts_vector_line <- sprintf("%s, hweight_prec = %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f\n", 
                               idate,
                               wts_vector[1], wts_vector[2], wts_vector[3], 
                               wts_vector[4], wts_vector[5], wts_vector[6], 
                               wts_vector[7], wts_vector[8], wts_vector[9], 
                               wts_vector[10], wts_vector[11], wts_vector[12],
                               wts_vector[13], wts_vector[14], wts_vector[15], 
                               wts_vector[16], wts_vector[17], wts_vector[18], 
                               wts_vector[19], wts_vector[20], wts_vector[21], 
                               wts_vector[22], wts_vector[23], wts_vector[24])
    cat(wts_vector_line, file = "era5_hourly_precipitation_weights_level5_mhm_nml.txt", append = TRUE)
  }

}

# ====================== DWD DATA
# Read DWD data
# Read the netCDF file
ncin <- nc_open(prefile_curr)
# get VARIABLE
dwd_pre_2d<- ncvar_get(ncin,"pre")  # [lon, lat, time]
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
tfinal <- as.Date(chron(nctime, origin=c(tmonth, tday, tyear))) # nctime (days)
# mask and fldmean
dwd_pre <- vector()
for (itime in 1:nt){
  # mask
  dwd_pre_2d[,,itime] <- ifelse(mask_germany_extent < 0, NA, dwd_pre_2d[,,itime])
  # fldmean
  dwd_pre[itime] <- mean(dwd_pre_2d[,,itime], na.rm = TRUE)
  }
# dellocate immediately
# rm(dwd_pre_2d)
# convert to xts
dwd_pre <- xts(as.numeric(dwd_pre), order.by = tfinal) # xts/ time series object created


# subset in time dimension for graph
# Process for Event forecast plot
dwd_pre_cut <- dwd_pre[paste(format(as.Date(paste(year, "/", month, "/", dStart-nDays_prior+1, sep = "")), "%Y-%m-%d"), "/",
                             format(as.Date(paste(year, "/", month, "/", dEnd, sep = "")), "%Y-%m-%d"), sep = "")]
dwd_pre_cut <- data.frame(dwd_pre_cut*precip_scaling) # scale!
dwd_pre_cut <- cbind(dwd_pre_cut, ylimitgraph - dwd_pre_cut) # inverse for bar stacking - circumventing ggplot2's inability for secondary axis plot!
dwd_pre_cut <- data.matrix(cbind(as.numeric(dwd_pre_cut[,1]), as.numeric(dwd_pre_cut[,2])))
dwd_pre_cut_melted <- melt(dwd_pre_cut ) # melt!
dwd_pre_cut_melted$X2[dwd_pre_cut_melted$X2 == 1] <- "white"
dwd_pre_cut_melted$X2[dwd_pre_cut_melted$X2 == 2] <- "dodgerblue" # give color
# Process for 2021 plot
dwd_pre_cut_2021 <- dwd_pre[paste(year, sep = "")]
dwd_pre_cut_2021 <- data.frame(dwd_pre_cut_2021*precip_scaling_2021) # scale!
dwd_pre_cut_2021 <- cbind(dwd_pre_cut_2021, ylimitgraph_2021 - dwd_pre_cut_2021) # inverse for bar stacking - circumventing ggplot2's inability for secondary axis plot!
# dwd_pre_cut_2021 <- data.matrix(cbind(as.numeric(dwd_pre_cut_2021[,1]), as.numeric(dwd_pre_cut_2021[,2])))
colnames(dwd_pre_cut_2021) <- c("white", "dodgerblue")
dwd_pre_cut_2021_melted <- melt(data.matrix(dwd_pre_cut_2021) ) # melt!
dwd_pre_cut_2021_melted$X1 <- as.Date(dwd_pre_cut_2021_melted$X1) # convert columns X1 from factor to Date




# ====================== Baseline mHM's SM DATA
# Read historical SM simulations
# Read the netCDF file
ncin <- nc_open(smfile_hist)
# get VARIABLE
mhm_sm_hist<- ncvar_get(ncin,"SM_Lall")  # [lon, lat, time]
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
mhm_sm_hist <- xts(as.numeric(mhm_sm_hist), order.by = tfinal) # xts/ time series object created
# SM climatology
  # Monthly 
  mhm_sm_hist_mon_mean <- as.matrix(monthlyfunction(mhm_sm_hist, FUN = mean))
  # Weekly 
  mhm_sm_hist_week_mean <- vector()
  for (week in 0:53){
    mhm_sm_hist_week_mean[week+1] <- mean(mhm_sm_hist[as.numeric(format(index(mhm_sm_hist), "%W")) == week ], na.rm = TRUE)
  }
  # DOY 
  mhm_sm_hist_doy_mean <- vector()
  for (doy in 1:366){
    mhm_sm_hist_doy_mean[doy] <- mean(mhm_sm_hist[as.numeric(format(index(mhm_sm_hist), "%j")) == doy ], na.rm = TRUE)
  }
  # Moving window climatology
  half_window = 3 # number of days around the day of interest
  mhm_sm_hist_movwin_mean <- vector()
  for (doy in 1:366){
    if (doy <= half_window){
      mhm_sm_hist_movwin_mean[doy] <- mean(mhm_sm_hist[as.numeric(format(index(mhm_sm_hist), "%j")) <= doy + half_window | 
                                                         as.numeric(format(index(mhm_sm_hist), "%j")) >= 366 + doy - half_window], na.rm = TRUE)
    } 
    else if (doy + half_window  > 366){
      mhm_sm_hist_movwin_mean[doy] <- mean(mhm_sm_hist[as.numeric(format(index(mhm_sm_hist), "%j")) <= doy + half_window - 366 | 
                                                         as.numeric(format(index(mhm_sm_hist), "%j")) >= doy - half_window], na.rm = TRUE)
    }
    else {
      mhm_sm_hist_movwin_mean[doy] <- mean(mhm_sm_hist[as.numeric(format(index(mhm_sm_hist), "%j")) <= doy + half_window & 
                                                         as.numeric(format(index(mhm_sm_hist), "%j")) >= doy - half_window], na.rm = TRUE)
    }
  }
  

# Read current SM simulations
# Read the netCDF file
ncin <- nc_open(smfile_curr)
# get VARIABLE
mhm_sm_curr<- ncvar_get(ncin,"SM_Lall") # 1d 
# Read time attribute
nctime <- ncvar_get(ncin,"time")
tunits <- ncatt_get(ncin,"time","units") 
nt <- dim(nctime)
tustr <- strsplit(tunits$value, " ")
tdstr <- strsplit(unlist(tustr)[3], "-")
tmonth <- as.integer(unlist(tdstr)[2])
tday <- as.integer(unlist(tdstr)[3])
# Prepare the time origin
tyear <- as.integer(unlist(tdstr)[1])
tfinal <- as.Date(chron(nctime/24, origin=c(tmonth, tday, tyear))) # nctime (days)
# convert to xts
mhm_sm_curr <- xts(as.numeric(mhm_sm_curr), order.by = tfinal) # xts/ time series object created
# SM anomaly
  # # Using monthly climatology - 
  # month_vector <- as.numeric(format(index(mhm_sm_curr), "%m"))
  # mhm_sm_ano <- data.matrix( (as.numeric(mhm_sm_curr) - mhm_sm_hist_mon_mean[month_vector]) * 100) # in percent
  # # Using weekly climatology - 
  # week_vector <- as.numeric(format(index(mhm_sm_curr), "%W"))
  # mhm_sm_ano <- data.matrix( (as.numeric(mhm_sm_curr) - mhm_sm_hist_week_mean[week_vector+1]) * 100) # in percent
  # # Using doy climatology -
  # doy_vector <- as.numeric(format(index(mhm_sm_curr), "%j"))
  # mhm_sm_ano <- data.matrix( (as.numeric(mhm_sm_curr) - mhm_sm_hist_doy_mean[doy_vector]) * 100) # in percent
  # Using moving window climatology -
  doy_vector <- as.numeric(format(index(mhm_sm_curr), "%j"))
  mhm_sm_ano <- data.matrix( (as.numeric(mhm_sm_curr) - mhm_sm_hist_movwin_mean[doy_vector]) * 100) # in percent
# Process for Event forecast plot
# convert to xts
mhm_sm_ano <- xts(as.numeric(mhm_sm_ano), order.by = tfinal) # xts/ time series object created
# scale!
mhm_sm_ano_scale <- sm_graph_yintercept_start + (sm_graph_yintercept_end - sm_graph_yintercept_start)/
              (sma_upper_limit - sma_lower_limit)*(mhm_sm_ano - sma_lower_limit) 
# subset in time dimension for graph
mhm_sm_ano_cut <- mhm_sm_ano_scale[paste(format(as.Date(paste(year, "/", month, "/", dStart-nDays_prior+1, sep = "")), "%Y-%m-%d"), "/", 
                             format(as.Date(paste(year, "/", month, "/", dEnd, sep = "")), "%Y-%m-%d"), sep = "")]
mhm_sm_ano_cut_melted <- melt(data.matrix(as.numeric(mhm_sm_ano_cut)) ) # melt!

# Process for 2021 plot
# subset in time dimension for graph
mhm_sm_ano_cut_2021 <- mhm_sm_ano[paste(year, sep = "")]
mhm_sm_ano_cut_2021_melted <- melt(data.matrix(mhm_sm_ano_cut_2021) ) # melt!
mhm_sm_ano_cut_2021_melted$X1 <- as.Date(mhm_sm_ano_cut_2021_melted$X1) # convert columns X1 from factor to Date



# ====================== Baseline mHM's Q DATA
# Read current Q simulations
# Read the netCDF file
ncin <- nc_open(qfile_curr)
# get VARIABLE
mhm_q_curr<- ncvar_get(ncin,"Qsim_0271804030")  # [lon, lat, time]
# Read time attribute
nctime <- ncvar_get(ncin,"time")
tunits <- ncatt_get(ncin,"time","units") 
nt <- dim(nctime)
# Prepare the time origin
tustr <- strsplit(tunits$value, " +")
tdstr <- strsplit(unlist(tustr)[3], "-")
tmonth <- as.integer(unlist(tdstr)[2])
tday <- as.integer(unlist(tdstr)[3])
tyear <- as.integer(unlist(tdstr)[1])
tfinal <- as.Date(chron(nctime/24, origin=c(tmonth, tday, tyear))) # nctime (days)
# convert to xts
mhm_q_curr <- xts(as.numeric(mhm_q_curr), order.by = tfinal) # xts/ time series object created
# get the flood day streamflow
q_mhm_floodday <- as.numeric(mhm_q_curr["2021-07-15"])
# subset in time dimension for graph
mhm_q_curr_cut <- mhm_q_curr[paste(format(as.Date(paste(year, "/", month, "/", dStart-nDays_prior+1, sep = "")), "%Y-%m-%d"), "/", 
                                         format(as.Date(paste(year, "/", month, "/", dEnd, sep = "")), "%Y-%m-%d"), sep = "")]
mhm_q_curr_cut_melted <- melt(data.matrix(as.numeric(mhm_q_curr_cut)) ) # melt!



# ====================== CLIMATE PROJECTIONS (HICAM) DATA
# Read data

# >>> HICAM runs (1970 - 2098)
# Look up table
climproj_lut <- read.delim(climproj_lut_file, sep = "", header = TRUE)
nclimproj_lut_entries <- length(climproj_lut[,1])


# loop over all lut entries
for (ientry in 1:nclimproj_lut_entries) { # LuT entries loop
  
  
  # read time attribute for first entry
  if (ientry == 1){
    # File name
    ncfile <- paste(climproj_fol, as.character(climproj_lut$met_id)[ientry], "mRM_Fluxes_States.nc", sep = "/")
    # Read the netCDF file
    ncin <- nc_open(ncfile)
    # Read time attribute
    nctime <- ncvar_get(ncin,"time")
    tunits <- ncatt_get(ncin,"time","units") 
    nt <- dim(nctime)
    tustr <- strsplit(tunits$value, " ")
    tdstr <- strsplit(unlist(tustr)[3], "-")
    tmonth <- as.integer(unlist(tdstr)[2])
    tday <- as.integer(unlist(tdstr)[3])
    # Prepare the time origin
    tyear <- as.integer(unlist(tdstr)[1])
    tfinal <- as.Date(chron(nctime/24, origin=c(tmonth, tday, tyear))) # nctime (days)
    
    # Initialize XTS
    mhm_q_climproj_rcp26_xts <- xts(vector(), order.by = tfinal)
    mhm_q_climproj_rcp85_xts <- xts(vector(), order.by = tfinal)
  }
    
  
  # check if its RCP 2.6 or RCP 8.5 or others
  if (as.character(climproj_lut$rcp[ientry]) == "rcp26" | as.character(climproj_lut$rcp[ientry]) == "rcp85"){
    
    # File name
    ncfile <- paste(climproj_fol, as.character(climproj_lut$met_id)[ientry], "mRM_Fluxes_States.nc", sep = "/")
    # Check if file is present
    if (file.exists(ncfile)){
      # Read the netCDF file
      ncin <- nc_open(ncfile)
      # get VARIABLE
      mhm_q_climproj <- ncvar_get(ncin,"Qrouted") # 1d 
      # convert to xts
      mhm_q_climproj_new_xts <- xts(as.numeric(mhm_q_climproj), order.by = tfinal)
      names(mhm_q_climproj_new_xts) <-as.character(climproj_lut$met_id)[ientry]
      
      # Store the data
      if (as.character(climproj_lut$rcp[ientry]) == "rcp26"){
        mhm_q_climproj_rcp26_xts <- cbind.xts(mhm_q_climproj_rcp26_xts, mhm_q_climproj_new_xts)
      } else if (as.character(climproj_lut$rcp[ientry]) == "rcp85"){
        mhm_q_climproj_rcp85_xts <- cbind.xts(mhm_q_climproj_rcp85_xts, mhm_q_climproj_new_xts)
      }
    }
    
  }
  
  print(paste("member ", as.character(climproj_lut$met_id)[ientry]))
  
} # end lut entries loop

# calculate maximum of whole TS and inteneded periods, for each member and store in corresponding array/s
max_hist_rcp26 <- apply(mhm_q_climproj_rcp26_xts["1971/2000"], 2, max) # apply with on the fly time subssetting of XTS ;)
max_hist_rcp85 <- apply(mhm_q_climproj_rcp85_xts["1971/2000"], 2, max) # 2 represents function is to be applied across each column
max_fut1_rcp26 <- apply(mhm_q_climproj_rcp26_xts["2001/2050"], 2, max)
max_fut1_rcp85 <- apply(mhm_q_climproj_rcp85_xts["2001/2050"], 2, max)
max_fut2_rcp26 <- apply(mhm_q_climproj_rcp26_xts["2051/2098"], 2, max)
max_fut2_rcp85 <- apply(mhm_q_climproj_rcp85_xts["2051/2098"], 2, max)

# melt rcp2.6
max_rcp26 <- cbind(max_hist_rcp26, max_fut1_rcp26, max_fut2_rcp26)
colnames(max_rcp26) <- c("hist", "fut1", "fut2")
max_rcp26_melted <- melt(max_rcp26)
max_rcp26_melted$X1 <- "rcp26"
# melt rcp8.5
max_rcp85 <- cbind(max_hist_rcp85, max_fut1_rcp85, max_fut2_rcp85)
colnames(max_rcp85) <- c("hist", "fut1", "fut2")
max_rcp85_melted <- melt(max_rcp85)
max_rcp85_melted$X1 <- "rcp85"
# combine melts
max_melted <- rbind(max_rcp26_melted, max_rcp85_melted)



# ---------------------------
# FLOOD FREQUENCY ANALYSIS
# ---------------------------
# get ranks
obsdata_lt_ann_max_ranks <- length(obsdata_lt_ann_max) + 1 - rank(obsdata_lt_ann_max, ties.method = c("average"))
# get return periods
obsdata_lt_ann_max_T <- (length(obsdata_lt_ann_max) + 1)/obsdata_lt_ann_max_ranks
# # plot checks
# plot(obsdata_lt_ann_max_T,obsdata_lt_ann_max)
# hist(obsdata_lt_ann_max)
# plot.new()
# lines(density(obsdata_lt_ann_max),col="red")
# plot(ecdf(obsdata_lt_ann_max))
# fit a linear equation between Q and log(T)
fit_QT <- lm(obsdata_lt_ann_max~log(obsdata_lt_ann_max_T))
# estimate the return period floods with the equation
q_10y_T <- fit_QT$coefficients[1] + fit_QT$coefficients[2]*log(10)
q_100y_T <- fit_QT$coefficients[1] + fit_QT$coefficients[2]*log(100)
# more return periods for Table 1
q_2y_T <- fit_QT$coefficients[1] + fit_QT$coefficients[2]*log(2)
q_5y_T <- fit_QT$coefficients[1] + fit_QT$coefficients[2]*log(5)
q_20y_T <- fit_QT$coefficients[1] + fit_QT$coefficients[2]*log(20)
# ---------------------------
# q_500y_T <- fit_QT$coefficients[1] + fit_QT$coefficients[2]*log(500)
# print(q_500y_T)
# --  Theoretical Probabilities 
# EVD I - Gumbel
# param_scale <- as.numeric(sqrt(6) * var(obsdata_lt_ann_max) / pi)
# param_location <- as.numeric(mean(obsdata_lt_ann_max) - 0.5772 * param_scale)
# obsdata_lt_ann_max_cdf_gumbel <- exp(-exp(-(obsdata_lt_ann_max - param_location)/param_scale)) 
# obsdata_lt_ann_max_T_gumbel <- 1/(1 - obsdata_lt_ann_max_cdf_gumbel)
# plot(obsdata_lt_ann_max_T_gumbel)
# plot(obsdata_lt_ann_max_T_gumbel,obsdata_lt_ann_max)


# ====================== FORECAST DATA

for (ilead in leadStart:leadEnd) { # Lead time loop
  
  for (iens in ensStart:ensEnd) { # Ensemble members loop
    
    
    # Parameters
    fName      = paste(dataPath, "/discharge_202107", dStart+ilead ,"_ens", iens, ".nc", sep="")
    
    
    # Read the netCDF file
    ncin <- nc_open(fName)
    
    # get VARIABLE and its attributes 
    qsim <- ncvar_get(ncin,"Qsim_0271804030") 
    
    # convert to dataframe
    df <- data.frame(qsim[1:nDays])
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
  
  ## Calculate ensemble probabilities for return periods for Table 1 
  print(paste("lead ",6-ilead-1, ", probability > T2, ", round(q_2y_T), ", is ", round(sum(df_ensembles[6-ilead,] >= q_2y_T)/nEns*100,1), sep = ""))
  print(paste("lead ",6-ilead-1, ", probability > T5, ", round(q_5y_T), ", is ", round(sum(df_ensembles[6-ilead,] >= q_5y_T)/nEns*100,1), sep = ""))
  print(paste("lead ",6-ilead-1, ", probability > T20, ", round(q_20y_T), ", is ",round(sum(df_ensembles[6-ilead,] >= q_20y_T)/nEns*100,1), sep = ""))
  
  
  
  # convert to matrix
  df_ensembles <- data.matrix(df_ensembles)
  
  # save as 3D variable (ndays, nens, nlead)
  df_ensembles_3d[,,ilead+1] <- df_ensembles
  
  # save statistics of ensemble
  df_median <- apply(df_ensembles, 1, median)
  df_min <- apply(df_ensembles, 1, min)
  df_max <- apply(df_ensembles, 1, max)
  
  # save statistics as 2D variable (ndays, nlead)
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
colnames(df_min_2d_melted) <- c("day", "lead", "min")
df_max_2d_melted <- melt(df_max_2d)
colnames(df_max_2d_melted) <- c("day", "lead", "max")
df_minmax_2d_melted <- cbind(df_min_2d_melted, df_max_2d_melted$max)
colnames(df_minmax_2d_melted) <- c("day", "lead", "min", "max")

# --- Checkpoint: Arrays melted 



# Conditional edit for lead time
for (ilead in leadStart:leadEnd) { # Lead time loop
  
  ## All ensembles ##
  # edit for x-axis
  index <- df_ensembles_3d_melted$X3 == ilead + 1
  df_ensembles_3d_melted$X1[index] <- df_ensembles_3d_melted$X1[index] -1 + ilead
  # (Var1 - 1) : as Var1 starts from 1 but should actually start from 0
  
  # edit for ensemble numbering
  df_ensembles_3d_melted$X2[index] <- df_ensembles_3d_melted$X2[index] + ilead * nEns
  
  
  ## Ensemble median ##
  # edit for x-axis
  index <- df_median_2d_melted$X2 == ilead + 1
  df_median_2d_melted$X1[index] <- df_median_2d_melted$X1[index] -1 + ilead
  
  
  ## Ensemble min max ##
  # edit for x-axis
  index <- df_minmax_2d_melted$lead == ilead + 1
  df_minmax_2d_melted$day[index] <- df_minmax_2d_melted$day[index] -1 + ilead
  df_min_2d_melted$day[index] <- df_min_2d_melted$day[index] -1 + ilead
  df_max_2d_melted$day[index] <- df_max_2d_melted$day[index] -1 + ilead
  
}

# --- Checkpoint: Melted arrays adjusted 




# ====================== GRAPH

# Prepare x-axis 
dayBreaks <- c(seq(-nDays_prior, nDays + nLead - 1, 5))
dayLabels <- c(seq(dStart - nDays_prior , dEnd + nLead, 5))
dayLabels <- c("", dayLabels[2:length(dayLabels)])


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
  
  # issue days translucent background
  annotate("rect", xmin =-1, xmax =17,  ymin = 40,  ymax = 200,  alpha = 0.7, fill = "white") +
  # issue days - vertical lines
  geom_vline(xintercept = 0, linetype = 1, color = clrs[1], size = 0.5, alpha = 0.5) +
  geom_vline(xintercept = 1, linetype = 1, color = clrs[2], size = 0.5, alpha = 0.5) +
  geom_vline(xintercept = 2, linetype = 1, color = clrs[3], size = 0.5, alpha = 0.5) +
  geom_vline(xintercept = 3, linetype = 1, color = clrs[4], size = 0.5, alpha = 0.5) +
  
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
  
  
  # ensemble bands (only fill, no bounds)
  geom_ribbon(data = df_minmax_2d_melted, aes( x = day, ymin = min, ymax = max,  group = lead, fill = as.factor(lead) ), linetype = 1, size = 0.3, alpha = 0.2) +
  # each ensemble
  geom_line(data = df_ensembles_3d_melted, aes( x = X1, y = value, group = X2, color = as.factor(X3)), linetype = 1, size = 0.1, alpha = 0.2) +
  # max (upper bound for ensemble bands)
  geom_line(data = df_max_2d_melted, aes( x = day, y = max, group = lead, color = as.factor(lead)), linetype = 1, size = 0.3, alpha = 0.5) +
  # medians
  geom_line(data = df_median_2d_melted, aes( x = X1, y = value, group = X2, color = as.factor(X2) ), linetype = 2, size = 0.5, alpha = 0.5) +
  
  # observed
  geom_line(data = df_obs_melted, aes( x = X1-nDays_prior, y = value), color = "red", linetype = 1, size = 1, alpha = 0.5) +
  
  # mHM Q foreced with DWD
  geom_line(data = mhm_q_curr_cut_melted, aes( x = X1-nDays_prior, y = value), color = "black", linetype = 1, size = 1, alpha = 0.5) +
  
  
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
  annotate("text", x = -0.4,   y = 122,  cex = 2, label = '5 days in advance', colour = "black", angle = 90) +
  annotate("text", x =  0.6,   y = 122,  cex = 2, label = '4 days in advance', colour = "black", angle = 90) +
  annotate("text", x =  1.6,   y = 122,  cex = 2, label = '3 days in advance', colour = "black", angle = 90) +
  annotate("text", x =  2.6,   y = 122,  cex = 2, label = '2 days in advance', colour = "black", angle = 90) +
  # Labels on the graph
  annotate("text", x =  -5.7, y = 125,  cex = 2, label = '10 year return period flood', colour = "black") +
  annotate("text", x =  -5.9,   y = 199,  cex = 2, label = '100 year return period flood', colour = "black") +
  # Legend using annotations
  annotate("rect", xmin =10, xmax =21.6,  ymin = 30,  ymax = 215,  alpha = 0.95, fill = "white", linetype = 1, color = "black") + # translucent background
  annotate("text", x = 18.5,   y = 190,  cex = 2, label = format('forecast ensemble', width = 45, justify = "left"), colour = "black") +
  annotate("rect", xmin =  11, xmax =  12,  ymin = 195,  ymax = 205,  alpha = 0.2, fill = clrs[1]) + 
  annotate("rect", xmin =  11, xmax =  12,  ymin = 180,  ymax = 190,  alpha = 0.2, fill = clrs[2]) + 
  annotate("rect", xmin =12.5, xmax =13.5,  ymin = 195,  ymax = 205,  alpha = 0.2, fill = clrs[3]) + 
  annotate("rect", xmin =12.5, xmax =13.5,  ymin = 180,  ymax = 190,  alpha = 0.2, fill = clrs[4]) + 
  annotate("text", x = 18.5,   y = 160,  cex = 2, label = format('upper bounds of ensemble', width = 40, justify = "left"), colour = "black") +
  annotate("segment", x =  11, xend =  12,  y = 165,  yend = 165,  alpha = 0.8, colour = clrs[1], size = 0.3) + 
  annotate("segment", x =  11, xend =  12,  y = 155,  yend = 155,  alpha = 0.8, colour = clrs[2], size = 0.3) + 
  annotate("segment", x =12.5, xend =13.5,  y = 165,  yend = 165,  alpha = 0.8, colour = clrs[3], size = 0.3) + 
  annotate("segment", x =12.5, xend =13.5,  y = 155,  yend = 155,  alpha = 0.8, colour = clrs[4], size = 0.3) + 
  annotate("text", x = 18.5,   y = 130,  cex = 2, label = format('individual ensemble forecasts', width = 40, justify = "left"), colour = "black") +
  annotate("segment", x =  11, xend =  12,  y = 135,  yend = 135,  alpha = 1, colour = clrs[1], size = 0.1) + 
  annotate("segment", x =  11, xend =  12,  y = 125,  yend = 125,  alpha = 1, colour = clrs[2], size = 0.1) + 
  annotate("segment", x =12.5, xend =13.5,  y = 135,  yend = 135,  alpha = 1, colour = clrs[3], size = 0.1) + 
  annotate("segment", x =12.5, xend =13.5,  y = 125,  yend = 125,  alpha = 1, colour = clrs[4], size = 0.1) + 
  annotate("text", x = 18.5,   y = 100,  cex = 2, label = format('ensemble medians', width = 45, justify = "left"), colour = "black") +
  annotate("segment", x =10.5, xend =12.0,  y = 105,  yend = 105,  alpha = 0.5, colour = clrs[1], size = 0.5, linetype = 2) + 
  annotate("segment", x =10.5, xend =12.0,  y =  95,  yend =  95,  alpha = 0.5, colour = clrs[2], size = 0.5, linetype = 2) + 
  annotate("segment", x =12.5, xend =14.0,  y = 105,  yend = 105,  alpha = 0.5, colour = clrs[3], size = 0.5, linetype = 2) + 
  annotate("segment", x =12.5, xend =14.0,  y =  95,  yend =  95,  alpha = 0.5, colour = clrs[4], size = 0.5, linetype = 2) + 
  annotate("text", x = 18.5,   y =  70,  cex = 2, label = format('observed', width = 51, justify = "left"), colour = "black") +
  annotate("segment", x =   11, xend = 13.5,  y =  70,  yend =  70,  alpha = 0.5, colour = "red", size = 1, linetype = 1) + 
  annotate("text", x = 18.5,   y =  45,  cex = 2, label = format('mHM', width = 51, justify = "left"), colour = "black") +
  annotate("segment", x =   11, xend = 13.5,  y =  45,  yend =  45,  alpha = 0.5, colour = "black", size = 1, linetype = 1) + 
  
  
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
  
  scale_y_continuous(name = expression(paste("Streamflow (",m^{3},".",s^{-1},")", sep = "")), expand = c(0.03,0), limits = c(sm_graph_yintercept_start - 20, ylimitgraph),
                     breaks = c(sm_graph_yintercept_start, 0.5*(sm_graph_yintercept_start+sm_graph_yintercept_end), sm_graph_yintercept_end, 
                                seq(0,200,100),seq(ylimitgraph - precip_limit*precip_scaling, ylimitgraph, precip_interval*precip_scaling)), 
                     labels = c(rep("",3), seq(0,200,100),rep("",precip_limit/precip_interval+1)), 
                     sec.axis = sec_axis(~./precip_scaling, name = paste("Precipitation (mm)", "SM anomaly (%)", sep = "\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t"), 
                                         breaks = c(sm_graph_yintercept_start/precip_scaling, 0.5*(sm_graph_yintercept_start+sm_graph_yintercept_end)/precip_scaling, sm_graph_yintercept_end/precip_scaling, 
                                                    seq(ylimitgraph/precip_scaling - precip_limit, ylimitgraph/precip_scaling, precip_interval)), 
                                         labels = c(sma_lower_limit, 0.5*(sma_lower_limit+sma_upper_limit), sma_upper_limit, rev(seq(0,precip_limit,precip_interval)))) ) +
  scale_x_continuous(name = "Day number in July month, 2021", expand = c(0, 0), breaks = c(dayBreaks), labels = c(dayLabels), limits = c(-nDays_prior, nDays + nLead - 1 + x_additional),
                     sec.axis = dup_axis(name ="", labels = c()) )

# Output
ggsave(main, file=paste(fNameOut, sep=""), width = 6, height = 4.5, units = "in", dpi = 300)


# ==========================
# 2021 Plot
# ==========================

# precipitation totals
  # Dates, position, calculations
  fdate1 = as.Date(paste(year, "/01/02", sep = ""))
  tdate1 = as.Date(paste(year, "/02/09", sep = ""))
  mdate1 = fdate1 + floor((tdate1 - fdate1)/2)
  prsum1 = paste(round(sum(dwd_pre[paste(fdate1,"/",tdate1, sep = "")])), " mm", sep = " ")
  
  fdate2 = as.Date(paste(year, "/03/08", sep = ""))
  tdate2 = as.Date(paste(year, "/03/21", sep = ""))
  mdate2 = fdate2 + floor((tdate2 - fdate2)/2)
  prsum2 = paste(round(sum(dwd_pre[paste(fdate2,"/",tdate2, sep = "")])), " mm", sep = " ")
  
  fdate3 = as.Date(paste(year, "/04/04", sep = ""))
  tdate3 = as.Date(paste(year, "/04/12", sep = ""))
  mdate3 = fdate3 + floor((tdate3 - fdate3)/2)
  prsum3 = paste(round(sum(dwd_pre[paste(fdate3,"/",tdate3, sep = "")])), " mm", sep = " ")
  
  fdate4 = as.Date(paste(year, "/05/01", sep = ""))
  tdate4 = as.Date(paste(year, "/05/27", sep = ""))
  mdate4 = fdate4 + floor((tdate4 - fdate4)/2)
  prsum4 = paste(round(sum(dwd_pre[paste(fdate4,"/",tdate4, sep = "")])), " mm", sep = " ")
  
  fdate5 = as.Date(paste(year, "/06/18", sep = ""))
  tdate5 = as.Date(paste(year, "/07/13", sep = ""))
  mdate5 = fdate5 + floor((tdate5 - fdate5)/2)
  prsum5 = paste(round(sum(dwd_pre[paste(fdate5,"/",tdate5, sep = "")])), " mm", sep = " ")


plot2021 <- ggplot() +
  
  # problematic window
  annotate("rect", xmin =as.Date(paste(year, "/06/18", sep = "")), xmax =as.Date(paste(year, "/07/13", sep = "")),
           ymin = sma_lower_limit_2021,  ymax = ylimitgraph_2021, alpha = 0.1, fill = "black") +
  
  # mid line for precip
  geom_hline(yintercept = 32.5, linetype = 3, size = 0.1, color = "black", alpha = 0.5) +
  # dwd precipitation
  geom_bar(data = dwd_pre_cut_2021_melted, aes( x = X1 , y = value, alpha = as.factor(X2)), fill = "dodgerblue",
           width = 1, linetype = 1, size = 0.5, stat = "identity", show.legend = FALSE, position = position_stack(reverse = TRUE)) +
  
  # zero line for sma
  geom_hline(yintercept = 0, linetype = 2, size = 0.4, color = "black", alpha = 0.5) +
  # mid line for sma
  geom_hline(yintercept = 10, linetype = 3, size = 0.1, color = "black", alpha = 0.5) +
  # mhm sma
  geom_point(data = mhm_sm_ano_cut_2021_melted, aes( x = X1, y = value), colour = "dodgerblue", size = 1, alpha = 0.75) +
  
  # separation hline
  geom_hline(yintercept = sma_upper_limit_2021, linetype = 1, size = 0.25, color = "black") +
  
  
  # precipitation totals
  annotate("segment", x =fdate1, xend =tdate1,  y = 40,  yend = 40,  alpha = 0.5, colour = "black", size = 0.2) + 
  annotate("text", x = mdate1, y = 38,  cex = 2, label = prsum1, colour = "black") +
  annotate("segment", x =fdate2, xend =tdate2,  y = 40,  yend = 40,  alpha = 0.5, colour = "black", size = 0.2) + 
  annotate("text", x = mdate2, y = 38,  cex = 2, label = prsum2, colour = "black") +
  annotate("segment", x =fdate3, xend =tdate3,  y = 40,  yend = 40,  alpha = 0.5, colour = "black", size = 0.2) + 
  annotate("text", x = mdate3, y = 38,  cex = 2, label = prsum3, colour = "black") +
  annotate("segment", x =fdate4, xend =tdate4,  y = 40,  yend = 40,  alpha = 0.5, colour = "black", size = 0.2) + 
  annotate("text", x = mdate4, y = 38,  cex = 2, label = prsum4, colour = "black") +
  annotate("segment", x =fdate5, xend =tdate5,  y = 37,  yend = 37,  alpha = 0.5, colour = "black", size = 0.2) + 
  annotate("text", x = mdate5, y = 35,  cex = 2, label = prsum5, colour = "black") +
  
  scale_alpha_manual(values = alphas) +
  guides(color=FALSE) + # exclude fill aesthetics in legend
  
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
    axis.title.y.left  = element_text(size=10, margin = margin(r = 10), colour = "black", hjust = 0), 
    axis.title.y.right = element_text(size=10, margin = margin(l = 10), colour = "black", hjust = 0), 
    panel.border = element_rect(colour = "black", fill=NA, size=0.5),
    panel.background = element_blank(),
    panel.grid = element_blank(),
    legend.position = 'none',
    plot.title = element_text(size = 4, hjust=c(1,1), margin = margin(b = -8)),
    plot.subtitle = element_text(size = 4, margin = margin(b = 2))) +
  
  scale_y_continuous(name = "SM anomaly (%)", expand = c(0.03,0), limits = c(sma_lower_limit_2021, ylimitgraph_2021),
                     breaks = c(seq(sma_lower_limit_2021,sma_upper_limit_2021,sma_interval_2021), 
                                seq(ylimitgraph_2021 - precip_limit_2021*precip_scaling_2021, ylimitgraph_2021, precip_interval_2021*precip_scaling_2021)), 
                     labels = c(seq(sma_lower_limit_2021,sma_upper_limit_2021,sma_interval_2021),
                                rep("",precip_limit_2021/precip_interval_2021+1)), 
                     
                     sec.axis = sec_axis(~./precip_scaling_2021, name = "Precipitation (mm)", 
                                         breaks = c(seq(sma_lower_limit_2021/precip_scaling_2021,sma_upper_limit_2021/precip_scaling_2021,sma_interval_2021/precip_scaling_2021),
                                                    seq(ylimitgraph_2021/precip_scaling_2021 - precip_limit_2021, ylimitgraph_2021/precip_scaling_2021, precip_interval_2021)), 
                                         labels = c(rep("",(sma_upper_limit_2021-sma_lower_limit_2021)/sma_interval_2021+1),
                                                    rev(seq(0,precip_limit_2021,precip_interval_2021)))) ) +
  
  scale_x_date(name = "Year 2021", date_breaks= "1 month", date_labels = "%b", expand = c(0,0))

# Output
ggsave(plot2021, file=paste(fNameOut_2021, sep=""), width = 6, height = 3, units = "in", dpi = 300)




# ==========================
# Climate Projections BoxPlot
# ==========================

plot_climproj <- ggplot() + 
  geom_boxplot(data = max_melted, aes(x = factor(X2, levels = c("hist", "fut1", "fut2")), y = value, color = as.factor(X1), fill = as.factor(X1) ), alpha = 0.6, varwidth = TRUE) + 
  
  # Flood day (15.07.2021) streamflow simulation - horizontal line
  geom_hline(yintercept = q_mhm_floodday, linetype = 5, size = 0.4, color = "black", show.legend = TRUE, alpha = 0.5) +
  # 10-yr return period flood - horizontal line
  geom_hline(yintercept = q_10y_T, linetype = 5, size = 0.4, color = "black", show.legend = TRUE, alpha = 0.5) +
  # 100-yr return period flood - horizontal line
  geom_hline(yintercept = q_100y_T, linetype = 2, size = 0.4, color = "black", show.legend = TRUE, alpha = 0.5) +
  
  # Labels on the graph
  annotate("text", x =  1, y = 144,  cex = 3, label = 'July 15 flood (mHM)', colour = "black") +
  annotate("text", x =  1, y = 118,  cex = 3, label = '10 year return period flood', colour = "black") +
  annotate("text", x =  1, y = 182,  cex = 3, label = '100 year return period flood', colour = "black") +

  scale_color_manual(values = c("blue1", "brown1"),
                     labels = c("RCP 2.6 (21)", 
                                "RCP 8.5 (49)")) +
  
  
  scale_fill_manual(values = c("blue1", "brown1"),
                    labels = c("RCP 2.6 (21)", 
                               "RCP 8.5 (49)")) +
  
  
  scale_alpha_manual(values = c(0.5, 0.6),
                     labels = c("RCP 2.6 (21)", 
                                "RCP 8.5 (49)")) +
  
  labs(fill='RCP scenarios', color='RCP scenarios') + 
  
  ggtitle("", subtitle = "boxplot shows distribution of maximum streamflow across projection ensemble") +
  
  theme(
    text=element_text(family = "Helvetica", colour = "black"),
    axis.ticks.length=unit(-0.2, "cm"), 
    axis.ticks = element_line(colour = "black", size = 0.5),
    axis.text.x = element_text(size=12, margin = margin(t = 10), colour = "black"), 
    axis.title.x = element_text(size=14, margin = margin(t = 10), colour = "black"),
    axis.text.y.left = element_text(size=12, margin = margin(r = 10), colour = "black"), 
    axis.text.y.right = element_text(size=12, margin = margin(l = 10), colour = "black"), 
    axis.title.y.left  = element_text(size=14, margin = margin(r = 15), colour = "black", hjust = c(0.5)), 
    axis.title.y.right = element_blank(),
    plot.subtitle = element_text(size = 10, colour = "blue"),
    panel.border = element_rect(colour = "black", fill=NA, size=1),
    panel.background = element_blank(),
    panel.grid.major = element_line(colour = alpha("black", 0.5), size=0.2, linetype = 3),
    legend.position = c(0.80, 0.85),
    legend.title = element_text(size = 14, colour = "blue", face = "bold"),
    legend.text = element_text(size = 12),
    legend.key.height = unit(1, "cm"),
    legend.key.width = unit(0.7, "cm"),
    legend.key = element_blank(),
    legend.background = element_blank()) +
  
  scale_x_discrete(name = "Periods", labels = c("1971-2000", "2001-2050", "2051-2098")) +
  
  scale_y_continuous(name = expression(paste("Maximum streamflow of the period (",m^{3},".",s^{-1},")", sep = "")), 
                     sec.axis = dup_axis(name ="")) 

# Output
ggsave(plot_climproj, file=paste(fNameOut_climproj, sep=""), width = 6, height = 6, units = "in", dpi = 300)
