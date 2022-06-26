######################################################################################################### 
##                            ---------------------------------------------------------------------------
## ========================== Forecast Scalability Comparision with SCC for reservoirs
##                            ----------------------------------------------------------------------------
## ---------- Code developer: 
## -------------------------  Pallav Kumar Shrestha pallav-kumar.shrestha@ufz.de ------
## -------------------------  5 May 2020 ----------------------------------------
#########################################################################################################




library(ggplot2)

ipath = "/Users/shresthp/Nextcloud/Cloud/macbook/01_work/R/scripts/13_mLM_forecast_scalability_w_wo_SCC/"
opath = "/Users/shresthp/Nextcloud/Cloud/macbook/01_work/R/scripts/13_mLM_forecast_scalability_w_wo_SCC/"
setwd(ipath)






# Get the data from the web !
CC <- read.table("./mean_Tprofile-CC.txt" ,  header=TRUE)
nCC <- read.table("./mean_Tprofile-nCC.txt" , header=TRUE)
CC$type <- "Cool core"
nCC$type <- "Non-cool core"
A <- rbind(CC, nCC)



# Make the plot
# ggplot(data=A) + 
ggplot(data=A, aes(x=r.r500, y=sckT, ymin=sckT.lo, ymax=sckT.up, fill=type, linetype=type)) +
geom_line() +
  # geom_ribbon(aes(x=r.r500, ymin=sckT.lo, ymax=sckT.up, fill=type, linetype=type, alpha=0.5)) + 
  geom_ribbon(alpha=0.5) +
  scale_x_log10() + 
  scale_y_log10() + 
  xlab(as.expression(expression( paste("Radius (", R[500], ")") ))) + 
  ylab("Scaled Temperature")

