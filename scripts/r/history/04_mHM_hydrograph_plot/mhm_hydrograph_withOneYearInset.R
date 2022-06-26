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
fName = "daily_discharge.out"
misVal = -9999.0
obsCol = 5
simCol = 6

# Set the basin name
bName = "Basin Name"
subtitle_text = "optimization function used"

# Set the IO directory
iopath = "./"

# Reading the discharge file
data = data.frame(read.delim(paste(iopath,fName,sep=""), header = TRUE, sep = ""))  # reading all the data
data[data == misVal] <- NA
dStart <- as.Date(paste(data[1,4],"-",data[1,3],"-",data[1,2],sep=""))  # Infering the start date
nData <- length(data[,1])
dEnd <- as.Date(paste(data[nData,4],"-",data[nData,3],"-",data[nData,2],sep=""))  # Infering the end date
date <- seq.Date(dStart,dEnd, by= "days")
qmax <- max(max(data[,obsCol],na.rm = TRUE),max(data[,simCol],na.rm = TRUE),na.rm = TRUE) # Finding the maximum value

## INSET preparation
#generate date
insetYear <- 1970
insetDate <-seq.Date(as.Date(paste(insetYear,"-01-01",sep=""), format = "%Y-%m-%d"),as.Date(paste(insetYear,"-12-31",sep=""), format = "%Y-%m-%d"),by=1)
#inset position
insetXminDate <- 
                 # start date
                 as.Date(paste(data[1,4],"-",data[1,3],"-",data[1,2],sep=""), format = "%Y-%m-%d") +
                 # date window
                 (as.Date(paste(data[nData,4],"-",data[nData,3],"-",data[nData,2],sep=""), format = "%Y-%m-%d") -  # end date
                 as.Date(paste(data[1,4],"-",data[1,3],"-",data[1,2],sep=""), format = "%Y-%m-%d")) *              # start date 
                 # start date as fraction of window
                 0.2

insetXmaxDate <- 
                # start date
                as.Date(paste(data[1,4],"-",data[1,3],"-",data[1,2],sep=""), format = "%Y-%m-%d") +
                # date window
                (as.Date(paste(data[nData,4],"-",data[nData,3],"-",data[nData,2],sep=""), format = "%Y-%m-%d") -  # end date
                   as.Date(paste(data[1,4],"-",data[1,3],"-",data[1,2],sep=""), format = "%Y-%m-%d")) *              # start date 
                # start date as fraction of window
                0.7
insetYmin <- qmax
insetYmax <- qmax*3 

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
statKGE <- round(KGE(data[,simCol],data[,obsCol],na.rm = TRUE),2)  # KGE 
statNSE <- round(NSE(data[,simCol],data[,obsCol],na.rm = TRUE),2)  # NSE

statPosX <- 
           # start date
           as.Date(paste(data[1,4],"-",data[1,3],"-",data[1,2],sep=""), format = "%Y-%m-%d") +
           # date window
           (as.Date(paste(data[nData,4],"-",data[nData,3],"-",data[nData,2],sep=""), format = "%Y-%m-%d") -  # end date
              as.Date(paste(data[1,4],"-",data[1,3],"-",data[1,2],sep=""), format = "%Y-%m-%d")) *              # start date 
           # start date as fraction of window
           0.1
statPosYkge <- qmax*2.7   # determining position for statistics
statPosYnse <- qmax*2.4


# Plotting the hydrograph
# jpeg(paste(iopath,fName,".",bName,".jpg",sep=""), width=10, height=5, units = "in", res = 300)

# main <- ggplot(data, aes(x=date)) + geom_line(aes(y=data[,obsCol], color="observation"), shape=1, size = 1) + # The color statement needs to be inside aes for the legend to appear
main <- ggplot(data, aes(x=date)) + geom_line(aes(y=data[,obsCol], color="observation")) + # The color statement needs to be inside aes for the legend to appear
        geom_line(aes(y=data[,simCol], color="mHM simulation")) +
        ggtitle("Streamflow comparison") +
        labs(subtitle = subtitle_text) +
        annotate("text", x = statPosX, y = statPosYkge, cex = 5, label = paste("KGE", statKGE, sep = " "), colour = "Grey25") +
        annotate("text", x = statPosX, y = statPosYnse,  cex = 5, label = paste("NSE", statNSE, sep = " "), colour = "Grey25") + 
        ylab(expression(paste("Daily streamflow [",m^{3},".",s^{-1},"]"))) + xlab("Year") +
        scale_colour_manual("", values = c("observation"="#00B454", "mHM simulation"="#FF3900")) +
        theme(
              text=element_text(family = "Helvetica", colour = "Grey25"), 
              axis.ticks.length=unit(-0.25, "cm"), 
              axis.ticks = element_line(colour = "Grey50"),
              axis.text.x = element_text(size=12,margin = margin(t = 10), colour = "Grey50"), 
              axis.title.x = element_text(size=12,margin = margin(t = 20), colour = "Grey25"), 
              axis.text.y = element_text(size=12,margin = margin(r = 10), colour = "Grey50"), 
              axis.title.y = element_text(size=12,margin = margin(r = 10), colour = "Grey25"), 
              panel.border = element_rect(colour = "Grey50", fill=NA, size=1), 
              panel.background = element_blank(), legend.position = c(0.95, 0.95),
              legend.justification = c(1, 0.8), legend.direction = "vertical",
              legend.background = element_rect(fill=alpha('white', 0)), 
              plot.title = element_text(size = 16, face = "bold"), 
              legend.text = element_text(size = 14), 
              legend.key.size = unit(2, 'lines'),
              legend.key = element_rect(fill = NA)) +
        guides(linetype = guide_legend(override.aes = list(size = 5))) +
        scale_x_date(date_breaks= "1 year", date_labels = "%Y", expand = c(0,0)) + # duplicating the axis for the top was not possible with date axis
        scale_y_continuous(sec.axis = dup_axis(name ="", labels = c()), limits = c(0,qmax*3), expand = c(0,0))  # adding extra space at the top for annotations

inset <- ggplot(insetData, aes(x=insetDate)) + 
  geom_line(aes(y=insetData[,obsCol], color="observation"), size = 1.1) + # The color statement needs to be inside aes for the legend to appear
  geom_line(aes(y=insetData[,simCol], color="mHM simulation"), size = 1.1) +
  ggtitle(paste("Year ", insetYear, sep = "")) +
  ylab(expression(paste("Q [",m^{3},".",s^{-1},"]"))) + xlab("") +
  scale_colour_manual("", values = c("observation"="#00B454", "mHM simulation"="#FF3900")) +
  theme(
        text=element_text(family = "Helvetica", colour = "Grey25"), 
        axis.ticks.length=unit(-0.25, "cm"), 
        axis.ticks = element_line(colour = "Grey50"),
        axis.text.x = element_text(size=10,margin = margin(t = 10), colour = "Grey50"), 
        axis.title.x = element_text(size=10,margin = margin(t = 20), colour = "Grey25"), 
        axis.text.y = element_text(size=12,margin = margin(r = 10), colour = "Grey50"), 
        axis.title.y = element_text(size=12,margin = margin(r = 10), colour = "Grey25"), 
        panel.border = element_rect(colour = "Grey50", fill=NA, size=1), 
        panel.background = element_blank(), 
        legend.position = "none", 
        plot.title = element_text(size = 15, face = "bold", hjust=c(1,1))) +
  scale_x_date(date_breaks= "1 month", date_labels = "%b", expand = c(0,0))


sub <- inset
plot <- main + annotation_custom(ggplotGrob(sub),
                         xmin=insetXminDate,
                         xmax=insetXmaxDate,
                         ymin=insetYmin,
                         ymax=insetYmax)


ggsave(plot, file=paste(iopath,fName,".",bName,".jpg",sep=""), width = 10, height = 5, units = "in")


# dev.off()



