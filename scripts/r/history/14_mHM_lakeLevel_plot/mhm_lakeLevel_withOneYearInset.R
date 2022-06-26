######################################################################################################### 
##                            ---------------------------------------------------------------------------
## ========================== Hydrograph Generation from mHM streamflow output (daily_dicharge.out)
##                            ----------------------------------------------------------------------------
## ---------- Code developer: 
## -------------------------  Pallav Kumar Shrestha pallav-kumar.shrestha@ufz.de ------
## -------------------------  13 March 2018 ----------------------------------------
#########################################################################################################

#### Gives one set of skill scores for the whole simulation period
#### + an inset of a selected year of interest

# Open libraries/ packages
library(ggplot2)
library(hydroGOF) # for using fucntions KGE and NSE


# Parameters
# fName = "daily_discharge_val.out"
fName = "lakeLevel.out"
misVal = -9999.0
obsCol = 5
simCol = 6

# Set the basin name
bName = "TresMarias"

# Set the IO directory
iopath = "/Users/shresthp/tmp/eve_data_sawam/sawam/data/processed/mlmdevelopment/mlm_test_area/tests/06_regulation_rev_DCL_2param_seasonality/03_output/dev/"

# Reading the lake level file
data = data.frame(read.delim(paste(iopath,fName,sep=""), header = TRUE, sep = ""))  # reading all the data
data[data == misVal] <- NA
dStart <- as.Date(paste(data[1,4],"-",data[1,3],"-",data[1,2],sep=""))  # Infering the start date
nData <- length(data[,1])
dEnd <- as.Date(paste(data[nData,4],"-",data[nData,3],"-",data[nData,2],sep=""))  # Infering the end date
date <- seq.Date(dStart,dEnd, by= "days")

## INSET preparation
#generate date
insetYear <- 1997
insetDate <-seq.Date(as.Date(paste(insetYear,"-01-01",sep=""), format = "%Y-%m-%d"),as.Date(paste(insetYear,"-12-31",sep=""), format = "%Y-%m-%d"),by=1)
#inset position
insetXminYear <- round((data[1,4] + data[nData,4])/2 - (data[nData,4] - data[1,4])/5)     # determining position for inset
insetXmaxYear <- round((data[1,4] + data[nData,4])/2 + (data[nData,4] - data[1,4])/3)     # determining position for inset
#Finding start line
leap_count <- 0
nyears <- insetYear - data[1,4]
for (i in data[1,4]:insetYear){
  if (i %% 4 ==0){
    leap_count <- leap_count + 1
  }
}
insetStartRow <- nyears * 365 + leap_count + 1
if (insetYear %% 4 ==0){
  insetEndRow   <- insetStartRow + 365
} else {
  insetEndRow   <- insetStartRow + 364
}
#Inset data
insetData <- data[insetStartRow:insetEndRow,]


# Preparing annotations for the graph
qmax <- max(max(data[,obsCol],na.rm = TRUE),max(data[,simCol],na.rm = TRUE),na.rm = TRUE) # Finding the maximum value
qmin <- min(min(data[,obsCol],na.rm = TRUE),min(data[,simCol],na.rm = TRUE),na.rm = TRUE) # Finding the minimum value
statKGE <- round(KGE(data[,6],data[,5],na.rm = TRUE),2)  # KGE 
statNSE <- round(NSE(data[,6],data[,5],na.rm = TRUE),2)  # NSE
statPos <- round(data[1,4] + (data[nData,4] - data[1,4])/8)  # determining position for statistics



# Plotting the lake level graph
jpeg(paste(iopath,fName,".", bName,".jpg",sep=""), width=9, height=3, units = "in", res = 300)

main <- ggplot(data, aes(x=date)) + geom_point(aes(y=data[,obsCol], color="observation"), shape=1, size = 1) + # The color statement needs to be inside aes for the legend to appear
        geom_line(aes(y=data[,simCol], color="mHM simulation")) +
        ggtitle("Lake level : Tres Marias") +
        annotate("text", x = as.Date(paste(statPos,"-06-01",sep=""), format = "%Y-%m-%d"), y = qmax+7, cex = 5, label = paste("KGE", statKGE, sep = " ")) +
        annotate("text", x = as.Date(paste(statPos,"-06-01",sep=""), format = "%Y-%m-%d"), y = qmax+2,  cex = 5, label = paste("NSE", statNSE, sep = " ")) + 
        ylab(expression(paste("Daily water level [masl]"))) + xlab("Year") +
        scale_colour_manual("", values = c("observation"="blue", "mHM simulation"="red")) +
        theme(text=element_text(family = "Helvetica"), axis.ticks.length=unit(-0.25, "cm"), axis.text.x = element_text(size=10, margin = margin(t = 10)), 
              axis.text.y = element_text(size=10, margin = margin(r = 10)), axis.title.y = element_text(size=10, margin = margin(r = 10)), 
              axis.title.x = element_text(size=10, margin = margin(t = 20)), panel.border = element_rect(colour = "black", fill=NA, size=1), 
              panel.background = element_blank(), legend.position = c(1, 1),legend.justification = c(1, 0.8), 
              legend.background = element_rect(fill=alpha('white', 0)), plot.title = element_text(size = 15, face = "bold"), legend.text = element_text(size=15)) +
        scale_x_date(date_breaks= "1 year", date_labels = "%Y", expand = c(0,0)) + # duplicating the axis for the top was not possible with date axis
        scale_y_continuous(sec.axis = dup_axis(name ="", labels = c()), limits = c(qmin,qmax+10), expand = c(0,0))  # adding extra space at the top for annotations

# inset <- ggplot(insetData, aes(x=insetDate)) + geom_point(aes(y=insetData[,obsCol], color="observation"), shape=1, size = 0.5) + # The color statement needs to be inside aes for the legend to appear
#   geom_line(aes(y=insetData[,simCol], color="mHM simulation")) +
#   ggtitle(paste("Year ", insetYear, sep = "")) +
#   ylab(expression(paste("WL [masl]"))) + xlab("") +
#   scale_colour_manual("", values = c("observation"="blue", "mHM simulation"="red")) +
#   theme(text=element_text(family = "Helvetica"), axis.ticks.length=unit(-0.25, "cm"), axis.text.x = element_text(margin = margin(t = 10)), 
#         axis.text.y = element_text(margin = margin(r = 10)), axis.title.y = element_text(margin = margin(r = 5)), 
#         axis.title.x = element_text(margin = margin(t = 5)), panel.border = element_rect(colour = "black", fill=NA, size=1), 
#         panel.background = element_blank(), legend.position = "none", plot.title = element_text(size = 15, face = "bold", hjust=c(1,1))) +
#   scale_x_date(date_breaks= "1 month", date_labels = "%b", expand = c(0,0))
# 
# 
# sub <- inset
# main + annotation_custom(ggplotGrob(sub), 
#                          xmin=as.Date(paste(insetXminYear,"-01-01",sep=""), format = "%Y-%m-%d"), 
#                          xmax=as.Date(paste(insetXmaxYear,"-01-01",sep=""), format = "%Y-%m-%d"),
#                          ymin=qmax*0.99, 
#                          ymax=qmax*1.05 )

main

dev.off()



