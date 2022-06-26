######################################################################################################### 
##                            ---------------------------------------------------------------------------
## ========================== Sensitivity Plots from mHM optimization output (dds_results.out)
##                            ----------------------------------------------------------------------------
## ---------- Code developer: 
## -------------------------  Pallav Kumar Shrestha pallav-kumar.shrestha@ufz.de ------
## -------------------------  6 May 2019 ----------------------------------------
#########################################################################################################


# Open libraries/ packages
library(ggplot2)
library(gridExtra)  # for using "grid.arrange" function
library(grid)

# Parameters
fName = "dds_results.out2"
nParam = 18           # number of gauges
nRowPlot = 5          # number of rows in the output multi graph
nColPlot = ceiling((nParam+2)/ nRowPlot)      # number of cols in the output multi graph

# Set the IO directory
iopath = "/Users/shresthp/Nextcloud/Cloud/macbook/01_work/R/scripts/05_mHM_ddsresults_plot/02_mlm_opti_sensitivity_test/02_isolated_lake_opti/"

# Reading the optimization file
data = data.frame(read.delim(paste(iopath,fName,sep=""), skip = 7, header=FALSE, sep = ""))  # reading all the data
data <- cbind(data[,1:2], data[,59:76]) # subsettting for lake parameters
nIte <- length(data[,1])    # count number of iterations on the file

# Parameter list of optimization (corresponds to FinalParam.nml)
param <- c( # Rule curve
            "top_of_inactive_pool",
            "top_of_conservation_pool",
            "top_of_flood_control_pool",
            "RCfuncWeightParameter",
            "RCfuncSlopeParameter",
            # Demand Curve
            "ann_avg_water_supply_flow",
            "ann_avg_environmental_flow",
            "ann_avg_hydropower_flow",
            "ann_avg_irrigation_flow",
            "DCfuncWeightParameter_hydropower",
            "DCfuncWeightParameter_irrigation",
            "DCfuncSlopeParameter_hydropower",
            "DCfuncSlopeParameter_irrigation",
            # Spill
            "inflow_flood_threshold",
            "dsControl_point_flood_threshold",
            # GWS
            "longterm_baseflow_feed",
            # Percolation
            "exponent_for_percolation",
            # Evaporation
            "MTTcoeff_for_evaporation")
  

# mask vector for parameters
mParam = c(# Rule curve
           1, 1, 1,
           1, 1, 
           # Demand Curve
           1, 1, 1, 1,
           1, 1, 1, 1,
           # Spill
           1, 1,
           # GWS
           1, 
           # Percolation 
           1,
           # Evaporation
           1 )   

# vector for parameters grouping (process based)
gParam = c(# Rule curve
          1, 1, 1,
          1, 1, 
          # Demand Curve
          2, 2, 2, 2,
          2, 2, 2, 2,
          # Spill
          3, 3,
          # GWS
          3, 
          # Percolation 
          3,
          # Evaporation
          3 ) 

cParam = c( "royalblue4", "coral", "lightseagreen")
#-----------------------------------------
# Plotting the sensitivity multi-plot

# Initialize
p <- list() # Defining p as list


# Dummy plot to display process parameter grouping
xplot <- ggplot() + xlim(0, 1) + ylim(0, 1) +
  theme(legend.position = "none", axis.title = element_blank(), axis.ticks = element_blank(),
        axis.text = element_blank(), plot.background = element_blank(), panel.background = element_blank()) +
  annotate("point", c(0, 0, 0), 
           c(0.75, 0.5, 0.25), 
           color = cParam, size = 5, alpha=0.8) +
  annotate("text", c(0.03, 0.03, 0.03), 
           c(0.75, 0.5, 0.25), 
           label = c("Rule Curve", "Demand Curve", "Others"), 
           size = 5, alpha=0.8, fontface="bold", hjust = 0) 

xplot = ggplotGrob(xplot)
p[[1]] <- xplot

maxX <- max(data[,2],na.rm = TRUE) # Finding the maximum x axis value
minX <- min(data[,2],na.rm = TRUE) # Finding the minimum x axis value

# Sensitivity plots
for (i in 1:nParam) { # Param loop
  
  maxY <- max(data[,i+2],na.rm = TRUE) # Finding the maximum y axis value
  minY <- min(data[,i+2],na.rm = TRUE) # Finding the minimum y axis value
  
  xplot <- ggplot(data, aes(x=data[,2])) + geom_point(aes(y=data[,i+2])) +
    ggtitle(param[i]) +
    theme(legend.position = "none", axis.title = element_blank(), 
          title = element_text(family = "Helvetica", size = 10)) +
  annotate("point", minX+0.9*(maxX-minX), minY+0.9*(maxY-minY) , size = 5,
           alpha=0.8, color=cParam[gParam[i]])
  
  xplot = ggplotGrob(xplot)
  p[[i+1]] <- xplot
  
}


xlay <- matrix(c(1,1, 2:(nParam+1)), nRowPlot, nColPlot, byrow = TRUE)

select_grobs <- function(lay) {
  id <- unique(c(t(lay))) 
  id[!is.na(id)]
}


# Plotting the hydrograph
pdf(paste(iopath,fName,".pdf",sep=""), width=24, height=12)
grid.arrange(grobs=p[select_grobs(xlay)], layout_matrix=xlay, 
             top = textGrob("\n mLM.TresMarias Isolation Optimisation: Sensitivity Analysis \n", 
                            gp=gpar(fontsize=20,font="Helvetica", just="left")))
dev.off()


