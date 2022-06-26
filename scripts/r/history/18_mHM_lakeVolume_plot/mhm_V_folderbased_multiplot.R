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


# Set the IO directory
iopath_parent = "/Users/shresthp/tmp/eve_data_sawam/sawam/data/processed/mlmdevelopment/mlm_test_area/tests/i150_OFdeltas/03_output/OR_combined/"


OFfolder <- c("40_dwl_kge", "41_dwl_nse", "42_dwl_sse", 
              "43_v_kge", "44_v_nse", "45_v_sse", 
              "46_dv_kge", "47_dv_nse", "48_dv_sse" 
              # "49_dq_kge", "50_dq_nse", "51_dq_sse"
)

OFtitle <- c("dWL KGE optimized", "dWL NSE optimized", "dWL SSE optimized",
             "V KGE optimized", "V NSE optimized", "V SSE optimized",
             "dV KGE optimized", "dV NSE optimized", "dV SSE optimized"
             # "dQ KGE optimized", "dQ NSE optimized", "dQ SSE optimized"
)


# Defining MULTIPLOT lists
plots <- list()
nColPlot <- 3
nRowPlot <- 3


for (iOF in 1:length(OFfolder)){  # Loop on


  # Parameters
  fName = "lakeVolume.out"
  misVal = -9999.0
  obsCol = 5
  simCol = 6
  
  # Set the basin name
  bName = "Tres Marias"
  subtitle_text = OFtitle[iOF]
  
  # Set the IO directory
  iopath = paste(iopath_parent, OFfolder[iOF], "/", sep = "")
  
  print(OFfolder[iOF])
  
  # Reading the discharge file
  data = data.frame(read.delim(paste(iopath,fName,sep=""), header = TRUE, sep = ""))  # reading all the data
  data[data == misVal] <- NA
  dStart <- as.Date(paste(data[1,4],"-",data[1,3],"-",data[1,2],sep=""))  # Infering the start date
  nData <- length(data[,1])
  dEnd <- as.Date(paste(data[nData,4],"-",data[nData,3],"-",data[nData,2],sep=""))  # Infering the end date
  date <- seq.Date(dStart,dEnd, by= "days")
  
  
  ## STAT annotations
  # Fin max-min
  qmax <- max(max(data[,obsCol],na.rm = TRUE),max(data[,simCol],na.rm = TRUE),na.rm = TRUE) # Finding the maximum value
  qmin <- min(min(data[,obsCol],na.rm = TRUE),min(data[,simCol],na.rm = TRUE),na.rm = TRUE) # Finding the minimum value
  # Calculate stats
  statKGE <- round(KGE(data[,simCol],data[,obsCol],na.rm = TRUE),2)  # KGE 
  statNSE <- round(NSE(data[,simCol],data[,obsCol],na.rm = TRUE),2)  # NSE
  statRMSE<- round(rmse(data[,simCol],data[,obsCol],na.rm = TRUE),0)  # RMSE
  
  # Find coordinates for stat annotations
  statPosX <- 
    # start date
    as.Date(paste(data[1,4],"-",data[1,3],"-",data[1,2],sep=""), format = "%Y-%m-%d") +
    # date window
    (as.Date(paste(data[nData,4],"-",data[nData,3],"-",data[nData,2],sep=""), format = "%Y-%m-%d") -  # end date
       as.Date(paste(data[1,4],"-",data[1,3],"-",data[1,2],sep=""), format = "%Y-%m-%d")) *              # start date 
    # start date as fraction of window
    0.1
  statPosYkge <- qmin + (qmax - qmin) *2.8   # determining position for statistics
  statPosYnse <- qmin + (qmax - qmin) *2.6
  statPosYrmse <- qmin + (qmax - qmin) *2.4
  
  
  
  ## INSET preparation
  # generate date
  insetYear <- 2001
  insetDate <-seq.Date(as.Date(paste(insetYear,"-01-01",sep=""), format = "%Y-%m-%d"),as.Date(paste(insetYear,"-12-31",sep=""), format = "%Y-%m-%d"),by=1)
  # inset position
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
  insetYmin <- qmin + (qmax - qmin) *1
  insetYmax <- qmin + (qmax - qmin) *3 
  
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
  

  
  # main <- ggplot(data, aes(x=date)) + geom_line(aes(y=data[,obsCol], color="observation"), shape=1, size = 1) + # The color statement needs to be inside aes for the legend to appear
  main <- ggplot(data, aes(x=date)) + geom_line(aes(y=data[,obsCol], color="observation")) + # The color statement needs to be inside aes for the legend to appear
          geom_line(aes(y=data[,simCol], color="mHM simulation")) +
          ggtitle("Lake Volume comparison") +
          labs(subtitle = subtitle_text) +
          annotate("text", x = statPosX, y = statPosYkge, cex = 5, label = paste("KGE", statKGE, sep = " ")) +
          annotate("text", x = statPosX, y = statPosYnse,  cex = 5, label = paste("NSE", statNSE, sep = " ")) + 
          annotate("text", x = statPosX, y = statPosYrmse,  cex = 5, label = paste("RMSE", statRMSE, "mcm", sep = " ")) + 
          ylab(expression(paste("Daily lake volume [mcm]"))) + xlab("Year") +
          scale_colour_manual("", values = c("observation"="blue", "mHM simulation"="red")) +
          theme(text=element_text(family = "Helvetica"), axis.ticks.length=unit(-0.25, "cm"), 
                axis.text.x = element_text(size=12,margin = margin(t = 10)), axis.title.x = element_text(size=12,margin = margin(t = 20)), 
                axis.text.y = element_text(size=12,margin = margin(r = 10)), axis.title.y = element_text(size=12,margin = margin(r = 10)), 
                panel.border = element_rect(colour = "black", fill=NA, size=1), panel.background = element_blank(), 
                legend.position = c(0.95, 0.95),legend.justification = c(1, 0.8), legend.direction = "vertical", legend.background = element_rect(fill=alpha('white', 0)), 
                plot.title = element_text(size = 16, face = "bold"), plot.subtitle = element_text(size = 20, face = "bold", hjust = c(1,1)),
                legend.text = element_text(size = 14), legend.key.size = unit(1.5, 'lines')) +
          scale_x_date(date_breaks= "1 year", date_labels = "%Y", expand = c(0,0)) + # duplicating the axis for the top was not possible with date axis
          scale_y_continuous(sec.axis = dup_axis(name ="", labels = c()), limits = c(qmin, qmin + (qmax - qmin)*3), expand = c(0,0))  # adding extra space at the top for annotations
  
  inset <- ggplot(insetData, aes(x=insetDate)) + geom_line(aes(y=insetData[,obsCol], color="observation")) + # The color statement needs to be inside aes for the legend to appear
    geom_line(aes(y=insetData[,simCol], color="mHM simulation")) +
    ggtitle(paste("Year ", insetYear, sep = "")) +
    ylab(expression(paste("V [mcm]"))) + xlab("") +
    scale_colour_manual("", values = c("observation"="blue", "mHM simulation"="red")) +
    theme(text=element_text(family = "Helvetica"), axis.ticks.length=unit(-0.25, "cm"), 
          axis.text.x = element_text(size=10,margin = margin(t = 10)), axis.title.x = element_text(size=10,margin = margin(t = 20)), 
          axis.text.y = element_text(size=12,margin = margin(r = 10)), axis.title.y = element_text(size=12,margin = margin(r = 10)), 
          panel.border = element_rect(colour = "black", fill=NA, size=1), 
          panel.background = element_blank(), legend.position = "none", plot.title = element_text(size = 15, face = "bold", hjust=c(1,1))) +
    scale_x_date(date_breaks= "1 month", date_labels = "%b", expand = c(0,0))
  
  
  sub <- inset
  main + annotation_custom(ggplotGrob(sub),
                           xmin=insetXminDate,
                           xmax=insetXmaxDate,
                           ymin=insetYmin,
                           ymax=insetYmax)
  
  # Append to multiplot 
  xplot <- ggplotGrob(main)
  plots[[iOF]] <- xplot 

} # Loop off


#--------------------------------
# Construct the MULTIPLOT & SAVE
#--------------------------------

# Defining the layout of the multiplot
xlay <- matrix(c(1:(nColPlot*nRowPlot)), nRowPlot, nColPlot, byrow = TRUE)

select_grobs <- function(lay) {
  id <- unique(c(t(lay))) # transpose ON if byrow = TRUE in xlay! If not, remove transpose!
  # id <- unique(c(lay))
  id[!is.na(id)]
}


# Output
pdf(paste(iopath_parent,fName,".",bName,".pdf",sep=""), width=10*nColPlot, height=5*nRowPlot)

grid.arrange(grobs=plots[select_grobs(xlay)], layout_matrix=xlay)

# Close PDF
dev.off()

