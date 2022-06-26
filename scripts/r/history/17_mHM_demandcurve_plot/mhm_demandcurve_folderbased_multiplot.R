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
DC_wsp = 17
DC_env = 18
DC_hpp = 19
DC_irr = 20



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
  
  
  # Preparing annotations for the graph
  maxval <- max(max(data[,DC_wsp:DC_irr],na.rm = TRUE),na.rm = TRUE) # Finding the maximum value
  minval <- min(min(data[,DC_wsp:DC_irr],na.rm = TRUE),na.rm = TRUE) # Finding the minimum value
  

  
  main <- ggplot(data, aes(x=date)) + 
          # Demand curve for water supply
          geom_line(aes(y=data[,DC_wsp], color="DC_wsp")) + # The color statement needs to be inside aes for the legend to appear
          # Demand curve for environmental release
          geom_line(aes(y=data[,DC_env], color="DC_env")) + 
          # Demand curve for hydropower
          geom_line(aes(y=data[,DC_hpp], color="DC_hpp")) + 
          # # Demand curve for irrigation
          # geom_line(aes(y=data[,DC_irr], color="DC_irr")) + 
    
          ylab(expression(paste("Demand [m3/s]"))) + xlab("Year") +
          ggtitle("Demand curves : Tres Marias") + 
          labs(subtitle = subtitle_text) +
    
          scale_colour_manual("", values = c("DC_wsp"="black", "DC_env"="blue", "DC_hpp"="red", "DC_irr"="green")) +
          theme(text=element_text(family = "Helvetica"), axis.ticks.length=unit(-0.25, "cm"), axis.text.x = element_text(size=10, margin = margin(t = 10)), 
                axis.text.y = element_text(size=10, margin = margin(r = 10)), axis.title.y = element_text(size=10, margin = margin(r = 10)), 
                axis.title.x = element_text(size=10, margin = margin(t = 20)), panel.border = element_rect(colour = "black", fill=NA, size=1), 
                panel.background = element_blank(), legend.position = "top", legend.justification = c(1, 0.8), plot.subtitle = element_text(size = 20, face = "bold", hjust = c(1,1)),
                legend.background = element_rect(fill=alpha('white', 0)), plot.title = element_text(size = 15, face = "bold"), legend.text = element_text(size=15)) +
          scale_x_date(date_breaks= "1 year", date_labels = "%Y", expand = c(0,0)) + # duplicating the axis for the top was not possible with date axis
          scale_y_continuous(sec.axis = dup_axis(name ="", labels = c()), limits = c(minval - (maxval-minval)*0.1, minval + (maxval-minval)*1.1), expand = c(0,0))  # adding extra space at the top for annotations
  
  
  
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
pdf(paste(iopath_parent,fName,"_DC.",bName,".pdf",sep=""), width=10*nColPlot, height=4*nRowPlot)

grid.arrange(grobs=plots[select_grobs(xlay)], layout_matrix=xlay)

# Close PDF
dev.off()


