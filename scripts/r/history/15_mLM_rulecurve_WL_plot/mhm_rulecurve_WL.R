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




#==================
# OPERATION CURVES
#==================

# Parameters
fName = "daily_regulation_lake2375.bal"
misVal = -9999.0
ToICol = 14
ToCCol = 15
ToFCCol = 16


# Set the basin name
bName = "TresMarias"
subtitle_text = "V KGE optimized"

# Set the IO directory
iopath = "/Users/shresthp/tmp/eve_data_sawam/sawam/data/processed/mlmdevelopment/mlm_test_area/tests/i150_OFdeltas/03_output/OR_combined/43_v_kge/"

# Reading the file
data = data.frame(read.delim(paste(iopath,fName,sep=""), header = TRUE, sep = "", skip = 3))  # reading all the data
data[data == misVal] <- NA
dStart <- as.Date(paste(data[1,4],"-",data[1,3],"-",data[1,2],sep=""))  # Infering the start date
nData <- length(data[,1])
dEnd <- as.Date(paste(data[nData,4],"-",data[nData,3],"-",data[nData,2],sep=""))  # Infering the end date
date <- seq.Date(dStart,dEnd, by= "days")


#==================
# WATER LEVEL
#==================

# Parameters
fName_wl = "lakeLevel.out"
misVal = -9999.0
obsCol = 5
simCol = 6

# Reading the lake level file
data_wl = data.frame(read.delim(paste(iopath,fName_wl,sep=""), header = TRUE, sep = ""))  # reading all the data_wl
data_wl[data_wl == misVal] <- NA


# Preparing annotations for the graph
maxval <- max(max(data[,ToFCCol],na.rm = TRUE), max(data_wl[,simCol],na.rm = TRUE), max(data_wl[,obsCol],na.rm = TRUE)) # Finding the maximum value
minval <- min(min(data[,ToICol],na.rm = TRUE), min(data_wl[,simCol],na.rm = TRUE), min(data_wl[,obsCol],na.rm = TRUE)) # Finding the minimum value

# Preparing stats for the graph
statKGE <- round(KGE(data_wl[,simCol],data_wl[,obsCol],na.rm = TRUE),2)  # KGE 
statNSE <- round(NSE(data_wl[,simCol],data_wl[,obsCol],na.rm = TRUE),2)  # NSE
statRMSE<- round(rmse(data_wl[,simCol],data_wl[,obsCol],na.rm = TRUE),2)  # RMSE

statPosX <- 
  # start date
  as.Date(paste(data[1,4],"-",data[1,3],"-",data[1,2],sep=""), format = "%Y-%m-%d") +
  # date window
  (as.Date(paste(data[nData,4],"-",data[nData,3],"-",data[nData,2],sep=""), format = "%Y-%m-%d") -  # end date
     as.Date(paste(data[1,4],"-",data[1,3],"-",data[1,2],sep=""), format = "%Y-%m-%d")) *              # start date 
  # start date as fraction of window
  0.1
statPosYkge <- minval + (maxval-minval)*1.35  # determining position for statistics
statPosYnse <- minval + (maxval-minval)*1.15
statPosYrmse <- minval + (maxval-minval)*1.15



#==================
# PLOT
#==================
jpeg(paste(iopath,fName,".",bName,".rulecurves.jpg",sep=""), width=10, height=6, units = "in", res = 300)

main <- ggplot(data, aes(x=date)) + 
        # Top of flood control
        geom_line(aes(y=data[,ToFCCol]) , color="blue", alpha = 1) + # The color statement needs to be inside aes for the legend to appear
        # Top of conservation
        geom_line(aes(y=data[,ToCCol]), color="green", alpha = 1) + 
        # Top of inactive
        geom_line(aes(y=data[,ToICol]), color="orange", alpha = 1) + 
        # mHM water level
        geom_line(aes(y=data_wl[,simCol], color="mHM reservoir level"), size = 2) + 
        # observed water level
        geom_line(aes(y=data_wl[,obsCol], color="observed reservoir level"), size = 2) +
        ylab(expression(paste("Elevation [masl]"))) + xlab("Year") +
        # ggtitle("Water level and Rule curves") + 
        # labs(subtitle = subtitle_text) +
        annotate("text", x = statPosX, y = statPosYkge, cex = 8, label = paste("KGE", statKGE, sep = " ")) +
        annotate("text", x = statPosX, y = statPosYnse,  cex = 8, label = paste("NSE", statNSE, sep = " ")) + 
        # annotate("text", x = statPosX, y = statPosYrmse,  cex = 5, label = paste("RMSE", statRMSE, "m", sep = " ")) + 
        scale_colour_manual("", values = c( "observed reservoir level"="black", "mHM reservoir level" = "red")) +
        theme(text=element_text(family = "Helvetica"), axis.ticks.length=unit(-0.25, "cm"),
              axis.text.x = element_text(size=14, margin = margin(t = 10)), axis.title.x = element_text(size=18, margin = margin(t = 20)),
              axis.text.y = element_text(size=14, margin = margin(r = 10)), axis.title.y = element_text(size=18, margin = margin(r = 10)),
              panel.border = element_rect(colour = "black", fill=NA, size=1), panel.background = element_blank(),
              legend.position = c("top"), legend.justification = c(1, 0.8), 
              legend.background = element_rect(fill=alpha('white', 0)), legend.text = element_text(size=22),
              plot.title = element_text(size = 18, face = "bold")) +
        scale_x_date(date_breaks= "1 year", date_labels = "%Y", expand = c(0,0)) + # duplicating the axis for the top was not possible with date axis
        scale_y_continuous(sec.axis = dup_axis(name ="", labels = c()), limits = c(minval - (maxval-minval)*0.1, minval + (maxval-minval)*1.5), expand = c(0,0))  # adding extra space at the top for annotations


main

dev.off()



