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


# Set the basin name
bName = "TresMarias"
subtitle_text = "dWL KGE optimized"

# Set the IO directory
iopath = "/Users/shresthp/tmp/eve_data_sawam/sawam/data/processed/mlmdevelopment/mlm_test_area/tests/i150_OFdeltas/03_output/OR_isolated/40_dwl_kge/"

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


# Plotting the rule curves
jpeg(paste(iopath,fName,".",bName,".demandcurves.jpg",sep=""), width=10, height=4, units = "in", res = 300)

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
              panel.background = element_blank(), legend.position = "top", legend.justification = c(1, 0.8), 
              legend.background = element_rect(fill=alpha('white', 0)), plot.title = element_text(size = 15, face = "bold"), legend.text = element_text(size=15)) +
        scale_x_date(date_breaks= "1 year", date_labels = "%Y", expand = c(0,0)) + # duplicating the axis for the top was not possible with date axis
        scale_y_continuous(sec.axis = dup_axis(name ="", labels = c()), limits = c(minval - (maxval-minval)*0.1, minval + (maxval-minval)*1.1), expand = c(0,0))  # adding extra space at the top for annotations


main

dev.off()



