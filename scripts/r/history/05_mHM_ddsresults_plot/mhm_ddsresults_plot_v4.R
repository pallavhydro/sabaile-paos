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
nParam = 74           # number of gauges
nRowPlot = 6          # number of rows in the output multi graph
nColPlot = ceiling((nParam+1)/ nRowPlot)      # number of cols in the output multi graph

# Set the IO directory
iopath = "/Users/shresthp/Nextcloud/Cloud/macbook/01_work/R/scripts/05_mHM_ddsresults_plot/02_mlm_opti_sensitivity_test/03_combined_opti/"

# Reading the optimization file
data = data.frame(read.delim(paste(iopath,fName,sep=""), skip = 7, header=FALSE, sep = ""))  # reading all the data
nIte <- length(data[,1])    # count number of iterations on the file

# Parameter list of optimization (corresponds to FinalParam.nml)
param <- c(  #interception1
            "canopyInterceptionFactor", 
            #snow1
            "snowTreshholdTemperature",      "degreeDayFactor_forest",          "degreeDayFactor_impervious", 
            "degreeDayFactor_pervious",      "increaseDegreeDayFactorByPrecip", "maxDegreeDayFactor_forest", 
            "maxDegreeDayFactor_impervious", "maxDegreeDayFactor_pervious", 
            #soilmoisture1
            "orgMatterContent_forest",       "orgMatterContent_impervious",     "orgMatterContent_pervious", 
            "PTF_lower66_5_constant",        "PTF_lower66_5_clay",              "PTF_lower66_5_Db", 
            "PTF_higher66_5_constant",       "PTF_higher66_5_clay",             "PTF_higher66_5_Db", 
            "PTF_Ks_constant",               "PTF_Ks_sand",                     "PTF_Ks_clay", 
            "PTF_Ks_curveSlope",             "rootFractionCoefficient_forest",  "rootFractionCoefficient_impervious", 
            "rootFractionCoefficient_pervious", "infiltrationShapeFactor", 
            #directRunoff1 
            "imperviousStorageCapacity", 
            #PET1
            "minCorrectionFactorPET",        "maxCorrectionFactorPET",          "aspectTresholdPET", 
            "HargreavesSamaniCoeff", 
            #interflow1  
            "interflowStorageCapacityFactor","interflowRecession_slope",        "fastInterflowRecession_forest", 
            "slowInterflowRecession_Ks",     "exponentSlowInterflow",
            #percolation1 
            "rechargeCoefficient",           "rechargeFactor_karstic",          "gain_loss_GWreservoir_karstic", 
            #routing3
            "slope_factor", 
            #geoparameter
            "GeoParam(1)",                   "GeoParam(2)",                     "GeoParam(3)", 
            "GeoParam(4)",                   "GeoParam(5)",                     "GeoParam(6)", 
            "GeoParam(7)",                   "GeoParam(8)",                     "GeoParam(9)", 
            "GeoParam(10)",                  "GeoParam(11)",                    "GeoParam(12)", 
            "GeoParam(13)",                  "GeoParam(14)",                    "GeoParam(15)", 
            "GeoParam(16)",
            # Rule curve
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
mParam = c(#interception1
            1,
            #snow1
            1, 1, 1,
            1, 1, 1,
            1, 1,
            #soilmoisture1
            1, 1, 1,
            1, 1, 1,
            1, 1, 1,
            1, 1, 1,
            1, 1, 1,
            1, 1,
            #directRunoff1 
            1,
            #PET1
            1, 1, 1,
            1,
            #interflow1 
            1, 1, 1,
            1, 1,
            #percolation1
            1, 1, 1,
            #routing2
            1,
            #geoparameter
            1, 1, 1,
            1, 1, 1,
            1, 1, 1,
            1, 1, 1,
            1, 1, 1,
            1,
            # Rule curve
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
gParam = c(#interception1
  1,
  #snow1
  2, 2, 2,
  2, 2, 2,
  2, 2,
  #soilmoisture1
  3, 3, 3,
  3, 3, 3,
  3, 3, 3,
  3, 3, 3,
  3, 3, 3,
  3, 3,
  #directRunoff1 
  4,
  #PET1
  5, 5, 5,
  5,
  #interflow1 
  6, 6, 6,
  6, 6,
  #percolation1
  7, 7, 7,
  #routing2
  8,
  #geoparameter
  9, 9, 9,
  9, 9, 9,
  9, 9, 9,
  9, 9, 9,
  9, 9, 9,
  9,
  # Rule curve
          10, 10, 10,
          10, 10, 
          # Demand Curve
          11, 11, 11, 11,
          11, 11, 11, 11,
          # Spill
          12, 12,
          # GWS
          12, 
          # Percolation 
          12,
          # Evaporation
          12 ) 

cParam = c("chartreuse3", "cornsilk4", "gold3", "royalblue4", 
           "coral", "lightseagreen", "royalblue1", "steelblue1", "brown4", "royalblue4", "coral", "lightseagreen")
#-----------------------------------------
# Plotting the sensitivity multi-plot

# Initialize
p <- list() # Defining p as list


# Dummy plot to display process parameter grouping
xplot <- ggplot() + xlim(0, 1) + ylim(0, 1) +
  theme(legend.position = "none", axis.title = element_blank(), axis.ticks = element_blank(),
        axis.text = element_blank(), plot.background = element_blank(), panel.background = element_blank()) +
  annotate("point", c(0, 0, 0, 0.25, 0.25, 0.25, 0.5, 0.5, 0.5, 0.75, 0.75, 0.75), 
           c(0.75, 0.5, 0.25, 0.75, 0.5, 0.25, 0.75, 0.5, 0.25, 0.75, 0.5, 0.25), 
           color = cParam, size = 5, alpha=0.8) +
  annotate("text",c(0.03, 0.03, 0.03, 0.28, 0.28, 0.28, 0.53, 0.53, 0.53, 0.78, 0.78, 0.78), 
           c(0.75, 0.5, 0.25, 0.75, 0.5, 0.25, 0.75, 0.5, 0.25,0.75, 0.5, 0.25), 
           label = c("interception1", "snow1", "soilmoisture1",
                     "directRunoff1", "PET1", "Interflow1",
                     "percolation1", "routing3", "geoparameter",
                     "Rule Curve", "Demand Curve", "Others"), 
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


xlay <- matrix(c(1,1, 1, 1, 2:(nParam+1)), nRowPlot, nColPlot, byrow = TRUE)

select_grobs <- function(lay) {
  id <- unique(c(t(lay))) 
  id[!is.na(id)]
}


# Plotting the hydrograph
pdf(paste(iopath,fName,".pdf",sep=""), width=24, height=12)
grid.arrange(grobs=p[select_grobs(xlay)], layout_matrix=xlay, 
             top = textGrob("\n mLM.TresMarias Combined Optimisation: Sensitivity Analysis \n", 
                            gp=gpar(fontsize=20,font="Helvetica", just="left")))
dev.off()


