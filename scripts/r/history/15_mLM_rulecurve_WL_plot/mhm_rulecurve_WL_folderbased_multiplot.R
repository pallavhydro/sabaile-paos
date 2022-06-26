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
              "46_dv_kge", "47_dv_nse", "48_dv_sse", 
              "49_dq_kge", "50_dq_nse", "51_dq_sse" )

OFtitle <- c("dWL KGE optimized", "dWL NSE optimized", "dWL SSE optimized",
             "V KGE optimized", "V NSE optimized", "V SSE optimized",
             "dV KGE optimized", "dV NSE optimized", "dV SSE optimized",
             "dQ KGE optimized", "dQ NSE optimized", "dQ SSE optimized")


# Defining MULTIPLOT lists
plots <- list()
nColPlot <- 3
nRowPlot <- 4

for (iOF in 1:length(OFfolder)){
  
  

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
  subtitle_text = OFtitle[iOF]
  
  # Set the IO directory
  iopath = paste(iopath_parent, OFfolder[iOF], "/", sep = "")
  
  print(OFfolder[iOF])
  
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
  statPosYnse <- minval + (maxval-minval)*1.25
  statPosYrmse <- minval + (maxval-minval)*1.15
  
  
  
  
  main <- ggplot(data, aes(x=date)) + 
          # Top of flood control
          geom_line(aes(y=data[,ToFCCol], color="ToFC"), alpha = 0.4) + # The color statement needs to be inside aes for the legend to appear
          # Top of conservation
          geom_line(aes(y=data[,ToCCol], color="ToC"), alpha = 0.4) + 
          # Top of inactive
          geom_line(aes(y=data[,ToICol], color="ToI"), alpha = 0.4) + 
          # mHM water level
          geom_line(aes(y=data_wl[,simCol], color="WL sim")) + 
          # observed water level
          geom_line(aes(y=data_wl[,obsCol], color="WL obs")) +
          ylab(expression(paste("Elevation [masl]"))) + xlab("Year") +
          ggtitle("Water level and Rule curves : Tres Marias") + 
          labs(subtitle = subtitle_text) +
          annotate("text", x = statPosX, y = statPosYkge, cex = 5, label = paste("KGE", statKGE, sep = " ")) +
          annotate("text", x = statPosX, y = statPosYnse,  cex = 5, label = paste("NSE", statNSE, sep = " ")) + 
          annotate("text", x = statPosX, y = statPosYrmse,  cex = 5, label = paste("RMSE", statRMSE, "m", sep = " ")) + 
          scale_colour_manual("", values = c("ToFC"="blue", "ToC"="green", "ToI"="orange", "WL obs"="black", "WL sim" = "red")) +
          theme(text=element_text(family = "Helvetica"), axis.ticks.length=unit(-0.25, "cm"),
                axis.text.x = element_text(size=12, margin = margin(t = 10)), axis.title.x = element_text(size=12, margin = margin(t = 20)),
                axis.text.y = element_text(size=12, margin = margin(r = 10)), axis.title.y = element_text(size=12, margin = margin(r = 10)),
                panel.border = element_rect(colour = "black", fill=NA, size=1), panel.background = element_blank(),
                legend.position = c("top"), legend.justification = c(1, 0.8), 
                legend.background = element_rect(fill=alpha('white', 0)), legend.text = element_text(size=15),
                plot.title = element_text(size = 15, face = "bold"), plot.subtitle = element_text(size = 20, face = "bold", hjust = c(1,1))) +
          scale_x_date(date_breaks= "1 year", date_labels = "%Y", expand = c(0,0)) + # duplicating the axis for the top was not possible with date axis
          scale_y_continuous(sec.axis = dup_axis(name ="", labels = c()), limits = c(minval - (maxval-minval)*0.1, minval + (maxval-minval)*1.5), expand = c(0,0))  # adding extra space at the top for annotations
  
  
  
  # Append to multiplot 
  xplot <- ggplotGrob(main)
  plots[[iOF]] <- xplot 

}# Loop off


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
pdf(paste(iopath_parent,fName,"_RCWL.",bName,".pdf",sep=""), width=10*nColPlot, height=6*nRowPlot)

grid.arrange(grobs=plots[select_grobs(xlay)], layout_matrix=xlay)

# Close PDF
dev.off()


