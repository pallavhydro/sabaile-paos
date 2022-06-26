######################################################################################################### 
##                            ---------------------------------------------------------------------------
## ========================== Ridgeline comparision: Reservoir regulation VS upstream meteorology
##                            ----------------------------------------------------------------------------
## ---------- Code developer: 
## -------------------------  Pallav Kumar Shrestha pallav-kumar.shrestha@ufz.de ------
## -------------------------  2 Feb 2020 ----------------------------------------
#########################################################################################################

#### Multiplot of reservoir regulation charateristics from upstream meteorology 
#### from mHM format time series files (daily data) and upstream meteorology file
#### from mLM

## Open libraries/ packages
# For data analysis
library(zoo) # for converting dataset to time series object
library(hydroTSM) # for manipulating time series object
# For graphics generation
library(ggridges)
library(ggplot2)
library(scales)
library(viridis)
library(hrbrthemes)
library(gridExtra)  # for using "grid.arrange" function

ipath = "/Users/shresthp/Nextcloud/Cloud/macbook/01_work/R/scripts/09_mLM_regulation_relation_ConnectedScatter/"
opath = "/Users/shresthp/Nextcloud/Cloud/macbook/01_work/R/scripts/10_mLM_regulation_relation_RidgeLinePlot/"
setwd(ipath)
abbrLakes = c("tma", "sob", "oro")
grandidLakes = c("2375", "2516", "2484")
nameLakes = c("Tr\u00E9s Marias", "Sobradinho", "Or\u00F3s")

nLakes = length(nameLakes) # number of lakes
misVal = -9999.0    # missing value in the output file




#---- Defining multiplot lists
plots <- list()
nColPlot <- 4
nRowPlot <- nLakes


## RESERVOIR LOOP HERE
for (i in 1:nLakes) {
  
  
  # Read observed water usage (hp or wsp)
  # R script read for daily INPUT data read in mHM format
  data <- read.delim(paste("input/", abbrLakes[i], "/h_ws_obs/", grandidLakes[i], ".lvl", sep=""), header = FALSE, skip = 5, sep = "")
  data[data == misVal] <- NA    # replacing missing values by NA
  data_hws_obs <- read.zoo(data[,-(4:5)], index.column = (1:3), format = "%Y %m %d") # construct zoo object using dates from the data itself
  
  # Read observed streamflow
  # R script read for daily INPUT data read in mHM format
  data <- read.delim(paste("input/", abbrLakes[i], "/q_ds_obs/", grandidLakes[i], ".txt", sep=""), header = FALSE, skip = 5, sep = "")
  data[data == misVal] <- NA    # replacing missing values by NA
  data_qds_obs <- read.zoo(data[,-(4:5)], index.column = (1:3), format = "%Y %m %d") # construct zoo object using dates from the data itself
  
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
  data_precip_ups_mon <- zoo(data[,2], data[,1])  # abstract precip data
  data_PET_ups_mon <- zoo(data[,4], data[,1])  # abstract PET data
  # data_tavg_ups_mon <- zoo(data[,3], data[,1])  # abstract tavg data
  
  # Calculate precip - PET
  data_precip_PET_ups_mon <- data_precip_ups_mon - data_PET_ups_mon
  
  # Convert daily time series to monthly
  data_hws_obs_mon <- daily2monthly(data_hws_obs, FUN=mean)
  data_qds_obs_mon <- daily2monthly(data_qds_obs, FUN=mean)
  
  
  ## Prepare data for plot
  # Combine monthly data
  data_mon <- cbind(data_precip_PET_ups_mon, data_hws_obs_mon, data_qds_obs_mon) # ADD RULE CURVE DATA HERE
  # Prepare months as factor with levels
  month <- month.abb[as.numeric(format(index(data_mon[,1]),"%m"))] # abstracting vector of months
  month <- factor(month, levels = month.abb) # creating factor and setting its levels
  
  ## Prepare color for plot
  color_precip_pet <- brewer.pal(n = 8, name = "RdYlBu")
  color_water_elev <- brewer.pal(n = 8, name = "Greys")
  color_streamflow <- brewer.pal(n = 8, name = "Blues")
    
  # # Conditional Transparancy <temporary for paper storyine concept figure>
  # if(i == 1 || i == 2 || i == 4){
  #   # show colors
  #   opacity = 1
  # } else {
  #   # no colors
  #   opacity = 0
  # }
  
  
  ## ==================| GRAPHICS |==============================
  # Ridgeline Plots
  
  ##== Upstream meteorology
  xplot <- ggplot(data_mon, aes(x = `data_precip_PET_ups_mon`, 
                       y = month, 
                       fill = ..x..)) +
    geom_density_ridges_gradient(scale = 3, rel_min_height = 0.01) +
    # scale_fill_viridis(option = "D") +
    # scale_fill_gradient(low = "white",
    #                     high = "dodgerblue4", 
    #                     space = "Lab")+
    scale_fill_gradientn(colours = color_precip_pet[-(1:2)]) +
    xlab("precip - PET \n (mm/ month)") +
    ylab("month") +
    labs( title = nameLakes[i]) +
    scale_x_continuous(breaks = breaks_extended(5)) +
    scale_y_discrete(expand = c(0,2)) +
    theme(text=element_text(family = "Helvetica"),
          axis.ticks.length=unit(-0.25, "cm"),
          axis.text.x = element_text(margin = margin(t = 15), size = 12),
          axis.text.y = element_text(margin = margin(r = 15), size = 12),
          axis.title.y = element_blank(),
          axis.title.x = element_text(margin = margin(t = 20), size = 14),
          axis.line.x.bottom = element_line(colour = "grey40" , size = 0.5),
          axis.line.y.left = element_line(colour = "grey40" , size = 0.5),
          panel.grid.major = element_line(color = "grey80", size = 0.2),
          panel.background = element_blank(),
          legend.position = "none",
          plot.title = element_text(size = 18),
          plot.subtitle = element_text(size = 12),
          plot.margin = margin(t=50))
  
  # Append to multiplot
  xplot <- ggplotGrob(xplot)
  plots[[(i-1)*nColPlot+1]] <- xplot
  
  
  ##== Water elevation
  xplot <- ggplot(data_mon, aes(x = `data_hws_obs_mon`, 
                                y = month, 
                                fill = ..x..)) +
    geom_density_ridges_gradient(scale = 3, rel_min_height = 0.01) +
    scale_fill_gradientn(colors = color_water_elev) +
    xlab("water elevation \n (masl)") +
    labs( title = '') +
    scale_x_continuous(breaks = breaks_extended(5)) +
    scale_y_discrete(expand = c(0,2)) +
    theme(text=element_text(family = "Helvetica"),
          axis.ticks.length=unit(-0.25, "cm"),
          axis.text.x = element_text(margin = margin(t = 15), size = 12),
          axis.text.y = element_text(margin = margin(r = 15), size = 12),
          axis.title.y = element_blank(),
          axis.title.x = element_text(margin = margin(t = 20), size = 14),
          axis.line.x.bottom = element_line(colour = "grey40" , size = 0.5),
          axis.line.y.left = element_line(colour = "grey40" , size = 0.5),
          panel.grid.major = element_line(color = "grey80", size = 0.2),
          panel.background = element_blank(),
          legend.position = "none",
          plot.title = element_text(size = 18),
          plot.subtitle = element_text(size = 12),
          plot.margin = margin(t=50))
  
  # Append to multiplot
  xplot <- ggplotGrob(xplot)
  plots[[(i-1)*nColPlot+2]] <- xplot
  
  
  ##== Top of Inactive
  # xplot <- ggplot() + geom_density_ridges_gradient() +
  xplot <- ggplot(data_mon, aes(x = `data_hws_obs_mon`,
                                y = month,
                                fill = ..x..)) +
    geom_density_ridges_gradient(scale = 3, rel_min_height = 0.01,
                                 alpha =0.1) +
    # scale_fill_gradientn(colors = color_water_elev[-8]) +
    xlab("rule curve for Top of Inactive \n (masl)") +
    labs( title = '') +
    scale_x_continuous(limits = c(400,500), breaks = breaks_extended(5)) +
    scale_y_discrete(expand = c(0,2)) +
    theme(text=element_text(family = "Helvetica"),
          axis.ticks.length=unit(-0.25, "cm"),
          axis.text.x = element_text(margin = margin(t = 15), size = 12, colour = "grey99"),
          axis.text.y = element_text(margin = margin(r = 15), size = 12),
          axis.title.y = element_blank(),
          axis.title.x = element_text(margin = margin(t = 20), size = 14),
          axis.line.x.bottom = element_line(colour = "grey40" , size = 0.5),
          axis.line.y.left = element_line(colour = "grey40" , size = 0.5),
          panel.grid.major = element_line(color = "grey80", size = 0.2),
          panel.background = element_blank(),
          legend.position = "none",
          plot.title = element_text(size = 18),
          plot.subtitle = element_text(size = 12),
          plot.margin = margin(t=50))
  
  # Append to multiplot
  xplot <- ggplotGrob(xplot)
  plots[[(i-1)*nColPlot+3]] <- xplot
  
  
  ##== Streamflow at downstream
  xplot <- ggplot(data_mon, aes(x = `data_qds_obs_mon`,
                                y = month,
                                fill = ..x..)) +
    geom_density_ridges_gradient(scale = 3, rel_min_height = 0.01)+
    scale_fill_gradientn(colors = color_streamflow[-8]) +
    xlab("streamflow at downstream \n (m3/s)") +
    labs( title = '') +
    scale_x_continuous(breaks = breaks_extended(5)) +
    scale_y_discrete(expand = c(0,2)) +
    theme(text=element_text(family = "Helvetica"),
          axis.ticks.length=unit(-0.25, "cm"),
          axis.text.x = element_text(margin = margin(t = 15), size = 12),
          axis.text.y = element_text(margin = margin(r = 15), size = 12),
          axis.title.y = element_blank(),
          axis.title.x = element_text(margin = margin(t = 20), size = 14),
          axis.line.x.bottom = element_line(colour = "grey40" , size = 0.5),
          axis.line.y.left = element_line(colour = "grey40" , size = 0.5),
          panel.grid.major = element_line(color = "grey80", size = 0.2),
          panel.background = element_blank(),
          legend.position = "none",
          plot.title = element_text(size = 18),
          plot.subtitle = element_text(size = 12),
          plot.margin = margin(t=50))

  # Append to multiplot
  xplot <- ggplotGrob(xplot)
  plots[[(i-1)*nColPlot+4]] <- xplot
  
} # Reservoir loop ends


# Defining the layout of the multiplot
xlay <- matrix(c(1:(nLakes*nColPlot)), nRowPlot, nColPlot, byrow = TRUE)

select_grobs <- function(lay) {
  id <- unique(c(t(lay))) # transpose ON if byrow = TRUE in xlay! If not, remove transpose!
  id[!is.na(id)]
}

# Output
setwd(opath)
pdf("regulation_hysteresis_ridgeline_rulecurve.pdf", width = 3*nColPlot, height = 6*nRowPlot) # each subplot is 5x8 inches
grid.arrange(grobs=plots[select_grobs(xlay)], layout_matrix=xlay)

# Close PDF
dev.off()

