######################################################################################################### 
##                            ---------------------------------------------------------------------------
## ========================== Plot generator for mLM scalability from metrics (e.g. NSE)
##                            ----------------------------------------------------------------------------
## ---------- Code developer: 
## -------------------------  Pallav Kumar Shrestha pallav-kumar.shrestha@ufz.de ------
## -------------------------  28 January 2020 ----------------------------------------
#########################################################################################################

#### Generates plots (radar plot, lollipop plot) from NSE performance across scales
#### The input file is a matrix of NSE metrics corresponding to optimization (source) scales [rows] and application (transfer) scales [cols]

# Open libraries/ packages
library(ggplot2)
library(ggradar)
library(dplyr)
library(scales)
library(tibble)

library(grid)
library(ggplotify)

# Set the input file and path
ipath = "/Users/shresthp/Nextcloud/Cloud/macbook/01_work/R/scripts/02_scalability_mlm/"
file_w = "with_reservoir_TME"
file_wo = "wo_reservoir_TME"
setwd(ipath)

# Reading the files, preparing the dfs

data_src_w = data.frame(read.delim(file_w, header = TRUE, sep = ","))  # read the data excluding the first header row of optimization scale
data_w <- as.data.frame(data_src_w[,-1]) # convert to data frame, excluding the first header column of application scale

data_src_wo = data.frame(read.delim(file_wo, header = TRUE, sep = ","))  # read the data excluding the first header row of optimization scale
data_wo <- as.data.frame(data_src_wo[,-1]) # convert to data frame, excluding the first header column of application scale


# Open PDF
# pdf("scalability_radar_ggradar.pdf", width = 7, height = 7)

## Reservoir loop here

  ## Optimization resolution loop here

    # To Do: 
    # 1. Add the multi-plot infrastructure from previous codes
    # 2. Multi-plot will be optimization resolution x reservoir i.e. a 5 x 9 matrix
  
    # Generate the plot data
    data <- rbind(data_w[1,], data_wo[1,]) # Bind the results from w/wo reservoirs
    colnames(data) <- paste( sprintf(data_src_wo[,1],fmt = '%#.2f'),"\u00B0",sep=" ") # retain two digits for resolution and add as column names to data frame
    ncol <- length(data[1,]) # get the number of corners for the radar plot
    data <- cbind(c("with reservoir", "wo reservoir"), data) # get the names for the plots in comparison
    
    
    # Color vector
    colors_border=c( rgb(1,0.57,0,0.9), rgb(0.36,0.36,0.36,0.9) )
    colors_in=c( rgb(1,0.57,0,0.4), rgb(0.36,0.36,0.36,0.7) )
    

    # Radar Plot
    ggradar(data,
            
            # Grid
            grid.min = 0,
            grid.max = 1,
            
            # Labels
            gridline.label.offset = -0.1,
            axis.label.offset = 1.2,
            axis.label.size = 5,
            
            # Axis
            values.radar = c(0,0.5,1),
            x.centre.range = 1,
            
            # Radars
            group.line.width = 1.5,
            group.point.size = 3,
            group.colours = colors_border,
            
            
            #legend
            plot.legend = FALSE,
            # legend.position = "top"
            
            # Title
            plot.title = 'Tr\u00E9s Marias \n 0.05 \u00B0'
            
            ) + theme(plot.title = element_text(hjust = NULL, size = 18)) + 
  
      # Annotate legend
      annotate(geom="segment", x = 0.8, xend = 1, y = 1.3, yend = 1.3, color=colors_border[1], size=3) +
      annotate(geom="segment", x = 0.8, xend = 1, y = 1, yend = 1, color=colors_border[2], size=3) +
      annotate(geom = "text", x = 1.45, y = 1.3, label = 'with mLM', size = 5) +
      annotate(geom = "text", x = 1.45, y = 1, label = 'w/o mLM', size = 5)
    

    # Close PDF
    # dev.off()