######################################################################################################### 
##                            ---------------------------------------------------------------------------
## ========================== Reservoir regulation characteristic (hysteresis) from upstream meteorology
##                            ----------------------------------------------------------------------------
## ---------- Code developer: 
## -------------------------  Pallav Kumar Shrestha pallav-kumar.shrestha@ufz.de ------
## -------------------------  1 Feb 2020 ----------------------------------------
#########################################################################################################

#### Multiplot of reservoir regulation charateristics from upstream meteorology 
#-- with lag 0-1-2
#### from mHM format time series files (daily data) and upstream meteorology file
#### from mLM

## Open libraries/ packages
# For data analysis
library(zoo) # for converting dataset to time series object
library(hydroTSM) # for manipulating time series object
library(data.table)
# For graphics generation
library(ggplot2)
library(hexbin)
library(dplyr)
library(ggrepel)
library(tidyr)
library(hrbrthemes)
library(gridExtra)  # for using "grid.arrange" function

ipath = "/Users/shresthp/Nextcloud/Cloud/macbook/01_work/R/scripts/09_mLM_regulation_relation_ConnectedScatter/"
setwd(ipath)
abbrLakes = c("tma", "sob", "oro")
grandidLakes = c("2375", "2516", "2484")
nameLakes = c("Tr\u00E9s Marias", "Sobradinho", "Or\u00F3s")
monLags = c(0, 1, 2)

nLakes = length(nameLakes) # number of lakes
nLags = length(monLags) # number of monthly lags to be checked
misVal = -9999.0    # missing value in the output file




#---- Defining multiplot lists
plots <- list()
nColPlot <- nLakes
nRowPlot <- nLags


## RESERVOIR LOOP HERE
for (i in 1:nLakes) {
  

  # Read observed water usage (hp or wsp)
  # R script read for daily INPUT data read in mHM format
  data <- read.delim(paste("input/", abbrLakes[i], "/q_use_obs/", grandidLakes[i], ".hyd", sep=""), header = FALSE, skip = 5, sep = "")
  data[data == misVal] <- NA    # replacing missing values by NA
  data_quse_obs <- read.zoo(data[,-(4:5)], index.column = (1:3), format = "%Y %m %d") # construct zoo object using dates from the data itself
  
  # # R script read for daily OUTPUT data read in mHM format
  # data <- read.delim("input/tma/q_ds_sim/daily_discharge.out", header = FALSE, skip = 1, sep = "")
  # data2[data == misVal] <- NA    # replacing missing values by NA
  # data2 <- read.zoo(data[,-1], index.column = (1:3), format = "%d %m %Y") # construct zoo object using dates from the data itself
  
  
  # Read monthly upstream precip and PET calculated from mLM
  # R script read for monthly caculated precip and PET data read in mLM format
  data <- read.delim(paste("input/", abbrLakes[i], "/ups_met/ups_met_for_lake", grandidLakes[i], ".out", sep=""), 
                     header = FALSE, sep = "")
  sdate <- as.Date(paste("1-",data[2,2],"-",data[2,3], sep = ""), format = "%d-%m-%Y" ) # generate date end points
  edate <- as.Date(paste("1-",data[3,2],"-",data[3,3], sep = ""), format = "%d-%m-%Y" )
  date <- seq.Date(sdate,edate, by= "months") # date vector
  data <- read.delim(paste("input/", abbrLakes[i], "/ups_met/ups_met_for_lake", grandidLakes[i], ".out", sep=""), 
                     header = FALSE, skip=4, sep = "") #re-read skipping first four lines
  data[data == misVal] <- NA    # replacing missing values by NA
  data <- cbind(date, data)     # bind the date to data
  data_tavg_ups_mon <- zoo(data[,3], data[,1])  # abstract tavg data
  
  # Convert daily hws to monthly hws
  data_quse_obs_mon <- daily2monthly(data_quse_obs, FUN=mean)
  
  
  ## Prepare data for plot
  # Combine monthly data
  data_mon <- cbind(data_tavg_ups_mon, data_quse_obs_mon)
  
    
  ## MONTHLY LAG LOOP HERE
  for (j in 1:nLags) {
    
    
    ## LAG the monthly meteorology using SHIFT
    data_mon <- cbind(shift(data_mon[,1], monLags[j], type="lag"), data_mon[,2])
    # Re-setup the column names
    colnames(data_mon) <- c("data_tavg_ups_mon","data_quse_obs_mon")
    # Cycle the month names according to the lag
    if (monLags[j] == 0) {
      monthnames <- month.name
    } else {
      monthnames <- c(tail(month.name, monLags[j]), head(month.name, -monLags[j])) # This doesn't work for 0 lag!
    }
    
    
    # Note: the data has been shifted by a lag of monLags[j]!!!
    
    # Generate Climatology
    data_mon_clim <- zoo(t(monthlyfunction(data_mon, FUN = median)))
    
    # Find out common time period overlap
    syear1 <- as.numeric(format(index(data_mon[first(which(!is.na(data_mon[,"data_tavg_ups_mon"])))]), "%Y"))
    syear2 <- as.numeric(format(index(data_mon[first(which(!is.na(data_mon[,"data_quse_obs_mon"])))]), "%Y"))
    eyear1 <- as.numeric(format(index(data_mon[last(which(!is.na(data_mon[,"data_tavg_ups_mon"])))]), "%Y"))
    eyear2 <- as.numeric(format(index(data_mon[last(which(!is.na(data_mon[,"data_quse_obs_mon"])))]), "%Y"))
    year_common_start <- max(syear1, syear2)
    year_common_end <- min(eyear1, eyear2)
    
    # Extract data at common time period
    data_common <- window(data_mon, 
                          start = as.Date(paste(year_common_start,"-1-1",sep="")), 
                          end = as.Date(paste(year_common_end,"-12-31",sep = "")))
    data_common <- as.xts(data_common) # converting to xts for faster subsetting
    # year with maximum water elevation
    year_max_hws <- as.numeric(format(index(data_common[which.max(data_common[,"data_quse_obs_mon"]),1]), "%Y"))
    # year with minimum water elevation
    year_min_hws <- as.numeric(format(index(data_common[which.min(data_common[,"data_quse_obs_mon"]),1]), "%Y"))
    # subset the max-min hws years
    data_mon_hws_max <- data_common[paste(year_max_hws)] # Note: doesn't work without paste!
    data_mon_hws_min <- data_common[paste(year_min_hws)]
    
    # # Conditional Transparancy <temporary for paper storyine concept figure>
    # if(i == 1 || i == 2 || i == 4){
    #   # show colors
    #   opacity = 1
    # } else {
    #   # no colors
    #   opacity = 0
    # }
    
    
    ## ==================| GRAPHICS |==============================
    # Connected scatterplots on top of basic Scatterplot
    
    # data_mon_clim %>%
      xplot <- ggplot(data=data_mon_clim, aes(x=data_tavg_ups_mon, y=data_quse_obs_mon)) +
        # All monthly data
        geom_point(data = data_mon, aes(x=data_tavg_ups_mon, y=data_quse_obs_mon),
                     color="black",
                     shape=16,
                     alpha=opacity*0.3,
                     size=1,
                     stroke=2
          ) +
        # Median hysteresis
        geom_point(data=data_mon_clim, 
                   aes(x=data_tavg_ups_mon, y=data_quse_obs_mon, color = "median hysteresis"), 
                   color="red",
                   size=4,
                   shape=16,
                   alpha=opacity) +
        geom_text_repel(data=data_mon_clim, 
                        aes(x=data_tavg_ups_mon, y=data_quse_obs_mon,
                            label=abbreviate(monthnames, # Circular shifting!!
                                             use.classes = FALSE, 
                                             minlength = 3, 
                                             strict = TRUE)),
                        alpha=opacity ) +
        geom_segment(data=data_mon_clim,
                     aes(xend=c(tail(data_tavg_ups_mon, n=-1), NA), 
                         yend=c(tail(data_quse_obs_mon, n=-1), NA)),
                     arrow=arrow(length=unit(0.2,"cm"), type = "closed"),
                     color="black", 
                     alpha = opacity*0.5,
                     size = 0.5 ) +
        # Max hws hysteresis
        geom_point(data=data_mon_hws_max, 
                   aes(x=data_tavg_ups_mon, y=data_quse_obs_mon, color="enclosing maximum water use"), 
                   color="blue3",
                   size=4,
                   shape=16,
                   alpha=opacity*0.3) +
        geom_segment(data=data_mon_hws_max,
                     aes(xend=c(tail(data_tavg_ups_mon, n=-1), NA), 
                         yend=c(tail(data_quse_obs_mon, n=-1), NA)),
                     arrow=arrow(length=unit(0.2,"cm"), type = "closed"),
                     color="black", 
                     alpha = opacity*0.3,
                     size = 0.5 ) +
        # Min hws hysteresis
        geom_point(data=data_mon_hws_min, 
                   aes(x=data_tavg_ups_mon, y=data_quse_obs_mon, color="enclosing minimum water use"), 
                   color="deepskyblue3",
                   size=4,
                   shape=16,
                   alpha=opacity*0.5) +
        geom_segment(data=data_mon_hws_min,
                     aes(xend=c(tail(data_tavg_ups_mon, n=-1), NA), 
                         yend=c(tail(data_quse_obs_mon, n=-1), NA)),
                     arrow=arrow(length=unit(0.2,"cm"), type = "closed"),
                     color="black", 
                     alpha = opacity*0.3,
                     size = 0.5 ) +
        xlab("average monthly temperature (\u00B0 C)") +
        ylab("observed water use (m3/s)") +
        labs(title = nameLakes[i], 
             subtitle = paste("lag:", monLags[j], "months", sep = " "),
             caption = paste(year_common_start, "-", year_common_end, sep = " ")) +
        scale_colour_manual(values = c("median hysteresis"="red", 
                                       'enclosing maximum water use'="blue3",
                                       'enclosing minimum water use'="deepskyblue3")) +
      theme(text=element_text(family = "Helvetica"), 
            axis.ticks.length=unit(-0.25, "cm"), 
            axis.text.x = element_text(margin = margin(t = 10)), 
            axis.text.y = element_text(margin = margin(r = 10)), 
            axis.title.y = element_text(margin = margin(r = 10)), 
            axis.title.x = element_text(margin = margin(t = 20)), 
            panel.border = element_rect(colour = "black", fill=NA, size=1), 
            panel.background = element_blank(), 
            legend.position = c(0.9, 0.9), 
            plot.title = element_text(size = 18), 
            plot.subtitle = element_text(size = 12))
    
    if( (i == 1) && (j == 1) ){
  
      # Annotate legend
      xplot <- xplot +
        annotate("point", x = 16, y = 800, color="red", size=3) +
        annotate("point", x = 16, y = 750, color="blue3", size=3) +
        annotate("point", x = 16, y = 700, color="deepskyblue3", size=3) +
        annotate("text", x = 18, y = 800,   label = 'median hysteresis    ', size = 4) +
        annotate("text", x = 18, y = 750,   label = 'incl. max water level', size = 4) +
        annotate("text", x = 18, y = 700,   label = 'incl. min water level', size = 4)
    }
  
    # Append to multiplot 
    xplot <- ggplotGrob(xplot)
    plots[[j+(i-1)*nLags]] <- xplot
  
  } # Monthly lag loop ends
  
} # Reservoir loop ends


# Defining the layout of the multiplot
xlay <- matrix(c(1:(nLakes*nLags)), nRowPlot, nColPlot, byrow = FALSE)

select_grobs <- function(lay) {
  id <- unique(c(lay)) # transpose ON if byrow = TRUE in xlay! If not, remove transpose!
  id[!is.na(id)]
}


# Output
pdf("regulation_hysteresis_connected_scatterplot_withLags_wateruse.pdf", width = 5*nColPlot, height = 5*nRowPlot) # each subplot is 5x5 inches
grid.arrange(grobs=plots[select_grobs(xlay)], layout_matrix=xlay) 

# Close PDF
dev.off()

