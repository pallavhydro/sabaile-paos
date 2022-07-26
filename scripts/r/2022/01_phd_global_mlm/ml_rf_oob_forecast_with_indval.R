
### RANDOM FOREST with INDEPENDENT VALIDATION 
###
### Author:     Pallav Kumar Shrestha
### Date:       24.07.2022
### Licence:    CC BY 4.0





##========================================
## LIBRARIES & FUNCTIONS
##========================================

library(randomForest)
library(stringr)
library(reshape) # for melt
library(hydroGOF) # for using fucntions KGE and NSE
source("~/git/gh/sabaile-paos/scripts/r/2022/01_phd_global_mlm/prepare_var_from_txt_input.R")
source("~/git/gh/sabaile-paos/scripts/r/history/28_mlm_plots/timeseries_line.R")


##========================================
## PATHS
##========================================

path_o = "~/work/projects/09_phd/03_sim/02_randomforest/rf_crossvalidation/"
path_d = "~/work/projects/09_phd/01_data/01_rappbode_rinke/processing/time_series/"



##========================================
## PARAMETER CONTROLS
##========================================
# time window 
sy0   = 1981          # incl. preditor build up period (2 years for Pre365lag365)
sy    = sy0 + 2       # 2 years excluded for Pre365lag365
ey    = 2019
nyr   = ey - sy + 1
nyr_t = 30            # number of years TRAINING
nyr_iv= nyr - nyr_t   # number of years INDEPENDENT VALIDATION; 

nrand_iter= 100 # number of ITERATIONS of RANDOMIZING year vector 


##========================================
## INITIALIZE for storage
##========================================
# performance matrix
per_mat_3d <- array(dim=c(5, 2, nrand_iter)) # nmetrics x ntimesplits x niterations
# model matrix
mod_mat_1d <- vector(mode = "list", length = nrand_iter) # niterations
# year matrices
yrs_t_mat_2d  <- array(dim = 0)
yrs_iv_mat_2d <- array(dim = 0)


##========================================
## READ Rappbode data
##========================================

dataxts_raw = prepare_var_from_txt_input(paste(path_d, "3195_outflow.txt", sep = "/"), "QoutRMD")
dataxts_raw = cbind(dataxts_raw, prepare_var_from_txt_input(paste(path_d, "2044_pre.txt", sep = "/"), "Pre"))
dataxts_raw = cbind(dataxts_raw, prepare_var_from_txt_input(paste(path_d, "2044_tavg.txt", sep = "/"), "Tavg"))



##========================================
## Store PREDICTAND and desired PREDICTORS
##========================================

# predictant
# -------------------
dataxts_pro = dataxts_raw$QoutRMD

# Time predictors
# -------------------
# doy
dataxts_pro$doy = as.numeric(strftime(index(dataxts_raw), format = "%j"))
# calendar week
dataxts_pro$woy = as.numeric(strftime(index(dataxts_raw), format = "%W"))
# month
dataxts_pro$month = as.numeric(strftime(index(dataxts_raw), format = "%m"))

# Meteorology predictors
# -------------------

# 3 days running pre sum
dataxts_pro$Pre3 = rollapply(dataxts_raw$Pre, 3, FUN = "sum", na.rm = TRUE)
# 1 week running pre sum
dataxts_pro$Pre7 = rollapply(dataxts_raw$Pre, 7, FUN = "sum", na.rm = TRUE)
# 30 day running pre sum
dataxts_pro$Pre30 = rollapply(dataxts_raw$Pre, 30, FUN = "sum", na.rm = TRUE)
# 30 day running tavg mean
dataxts_pro$Tavg30 = rollapply(dataxts_raw$Tavg, 30, FUN = "mean", na.rm = TRUE)
# 365 days running pre sum
dataxts_pro$Pre365 = rollapply(dataxts_raw$Pre, 365, FUN = "sum", na.rm = TRUE)

# Pre30 with 30 days lag
dataxts_pro$Pre30lag30 = c( rep(NA,30), as.numeric(head( dataxts_pro$Pre30, -30 )) ) 
# Pre365 with 365 days lag
dataxts_pro$Pre365lag365 = c( rep(NA,365), as.numeric(head( dataxts_pro$Pre365, -365 )) )

# NaN with 0
dataxts_pro[is.na(dataxts_pro)] = 0

# Subset experiment time window
dataxts_pro = dataxts_pro[paste(sy,"/",ey, sep = "")]





##========================================
## Iterations of RF with RANDOMISED YEARS
##========================================


# years vector in chronology
yrs = seq(sy, ey) 

# control the seed for randomisation
set.seed(1) 

# stop watch
start.time <- Sys.time()



for (iter in 1: nrand_iter){
  
  
  
  ## RANDOMIZE years
  ##========================================
  
  # years vector in random order
  yrs_random = sample(yrs) 
  
  # years vector for training
  yrs_t = yrs_random[1: nyr_t] 
  
  # years vector for independent validation
  yrs_iv   = yrs_random[(nyr_t + 1) : nyr] 
  
  
  

  ## SUBSET data
  ##========================================
  
  # Training
  # -------------------
  data_t = as.data.frame(coredata(dataxts_pro[c(as.character(yrs_t))]))
  date_t = index(dataxts_pro[c(as.character(yrs_t))])
  data_t_xts = dataxts_pro[c(as.character(yrs_t))]
  
  # Independent-Validation
  # -------------------
  data_iv = as.data.frame(coredata(dataxts_pro[c(as.character(yrs_iv))]))
  date_iv = index(dataxts_pro[c(as.character(yrs_iv))])
  data_iv_xts = dataxts_pro[c(as.character(yrs_iv))]
  
  
  
  ## RANDOM FOREST OOB ("out-of-bag") fit
  # ========================================
  
  rf_mod = randomForest(QoutRMD~., data=data_t, importance=TRUE)
  
  
  
  ## Forecasts
  # ========================================
  
  # TRAINING forecast
  # -------------------
  ymod_t = predict(rf_mod)
  ymod_t_xts = as.xts(ymod_t, order.by = date_t )
  
  # INDEPENDENT VALIDATION forecast
  # -------------------
  ymod_iv = predict(rf_mod, newdata = data_iv )
  ymod_iv_xts = as.xts(ymod_iv, order.by = date_iv )
  
  
  
  # Calculate and Store PERFORMANCE METRICS
  # ========================================  
  per_mat_3d[ 1, 1, iter]   <- round(KGE(ymod_t,data_t$QoutRMD,na.rm = TRUE),2)  # KGE 
  kge_terms                    <- as.numeric(unlist(KGE(ymod_t, data_t$QoutRMD, na.rm = TRUE, out.type = "full")[2]))
  per_mat_3d[ 2, 1, iter]   <- round(kge_terms[1], 2) # correlation
  per_mat_3d[ 3, 1, iter]   <- round(kge_terms[2], 2) # mean
  per_mat_3d[ 4, 1, iter]   <- round(kge_terms[3], 2) # variability measure
  per_mat_3d[ 5, 1, iter]   <- round(NSeff(ymod_t,data_t$QoutRMD,na.rm = TRUE),2)  # NSE
  
  per_mat_3d[ 1, 2, iter]   <- round(KGE(ymod_iv,data_iv$QoutRMD,na.rm = TRUE),2)  # KGE 
  kge_terms                    <- as.numeric(unlist(KGE(ymod_iv, data_iv$QoutRMD, na.rm = TRUE, out.type = "full")[2]))
  per_mat_3d[ 2, 2, iter]   <- round(kge_terms[1], 2) # correlation
  per_mat_3d[ 3, 2, iter]   <- round(kge_terms[2], 2) # mean
  per_mat_3d[ 4, 2, iter]   <- round(kge_terms[3], 2) # variability measure
  per_mat_3d[ 5, 2, iter]   <- round(NSeff(ymod_iv,data_iv$QoutRMD,na.rm = TRUE),2)  # NSE
  
  
  # STORE MODEL
  # ========================================
  mod_mat_1d[[iter]] <- rf_mod
  
  
  # STORE YEAR VECTORS
  # ========================================
  yrs_t_mat_2d  <- rbind( yrs_t_mat_2d,  yrs_t)
  yrs_iv_mat_2d <- rbind(yrs_iv_mat_2d, yrs_iv)
  
  
  # COMMUNICATE
  # ========================================
  message = paste("iteration", iter, ", KGEs: ", 
              per_mat_3d[ 1, 1, iter],
              per_mat_3d[ 1, 2, iter], "\n", sep = " ")
  
  print(message)
  cat(message, file = paste(path_o, "/iteration_output.txt", sep = ""), append = TRUE)
  
  
  rm(yrs_random, yrs_t, yrs_iv, 
     data_t, date_t, data_t_xts, 
     data_iv, date_iv, data_iv_xts, 
     ymod_t, ymod_t_xts, ymod_iv, ymod_iv_xts)

  
} # Iteration loop


# stop watch
end.time <- Sys.time()



# Runtime
print(paste("Started at:  ", start.time, sep = ""))
print(paste("Finished at: ", end.time, sep = ""))

# Output
write.table(yrs_t_mat_2d, file=paste(path_o, "/yrs_t_mat_2d.txt", sep = ""), sep=",", quote = F, row.names = F)
write.table(yrs_iv_mat_2d, file=paste(path_o, "/yrs_iv_mat_2d.txt", sep = ""), sep=",", quote = F, row.names = F)


##========================================
## Identify BEST MODEL PERFORMANCE from Cross Validation
##========================================













# # ========================================
# ## Plots
# # ========================================
# 
# 
# ## Plot SIGNIFICANCE of PREDICTORS
# # -------------------------------------
# pdf(file=paste(path_w, "significance_of_predictors.pdf" , sep="/"), width = 6, height = 6)
# imp_plot <- varImpPlot(rf_mod, type="1", col="blue")
# dev.off()
# 
# 
# ## Plot HYDROGRAPH
# # -------------------------------------
# 
# # Metrics
# statR2_t <- round(cor(ymod_t,data_t$QoutRMD)^2,2)  # R2 
# statKGE_t <- round(KGE(ymod_t,data_t$QoutRMD,na.rm = TRUE),2)  # KGE 
# statNSE_t <- round(NSeff(ymod_t,data_t$QoutRMD,na.rm = TRUE),2)  # NSE
# statPBS_t <- round(pbias(ymod_t,data_t$QoutRMD,na.rm = TRUE),2)  # PBIAS
# 
# statR2_cv <- round(cor(ymod_cv,data_cv$QoutRMD)^2,2)  # R2 
# statKGE_cv <- round(KGE(ymod_cv,data_cv$QoutRMD,na.rm = TRUE),2)  # KGE 
# statNSE_cv <- round(NSeff(ymod_cv,data_cv$QoutRMD,na.rm = TRUE),2)  # NSE
# statPBS_cv <- round(pbias(ymod_cv,data_cv$QoutRMD,na.rm = TRUE),2)  # PBIAS
# 
# statR2_iv <- round(cor(ymod_iv,data_iv$QoutRMD)^2,2)  # R2 
# statKGE_iv <- round(KGE(ymod_iv,data_iv$QoutRMD,na.rm = TRUE),2)  # KGE 
# statNSE_iv <- round(NSeff(ymod_iv,data_iv$QoutRMD,na.rm = TRUE),2)  # NSE
# statPBS_iv <- round(pbias(ymod_iv,data_iv$QoutRMD,na.rm = TRUE),2)  # PBIAS
# 
# 
# # Bind
# data_xts = dataxts_pro[paste(sy_t,"/",ey_iv, sep = "")]
# date_full= index(data_xts)
# plot_data <- cbind(data_xts$QoutRMD, ymod_t_xts, ymod_cv_xts, ymod_iv_xts)
# 
# # Melt
# plot_data_df <- data.frame(plot_data)
# plot_data_df$id <- rownames(plot_data_df)
# plot_data_melted <- melt(plot_data_df)
# # id must be date class
# plot_data_melted$id <- rep( date_full, length(plot_data[1,]))
# 
# 
# # Create table of metrics
# plot_table <- matrix( c(statR2_t, statR2_cv, statR2_iv,
#                         statKGE_t, statKGE_cv, statKGE_iv,
#                         statNSE_t, statNSE_cv, statNSE_iv,
#                         statPBS_t, statPBS_cv, statPBS_iv), 
#                       byrow = F, ncol = 4)
# colnames(plot_table) = c("R2", "KGE", "NSE", "Bias (%)")
# rownames(plot_table) = c("training","cross-val","ind.-val") 
# 
# 
# # plot hydrograph
# if("randomForest" %in% (.packages())){
#   detach("package:randomForest", unload = TRUE) # necessary to prevent conflict with ggplot2 in plot functions
# }
# plot_timeseries_line(plot_data_melted, path_w, "rf_t_cv_iv.pdf", 
#                      "RAPPBODE OUTFLOW \n\nRandom Forest 'out-of-box' forecast", "outflow [m3/s]", "",
#                      c("black", "blue", "green", "red"), c(rep(0.5, 4)), 
#                      c("observed", "training","cross-val","ind.-val"), 
#                      c(0.75, 0.9), "5 year", "%Y", c(0, 10), plot_table)
# 
