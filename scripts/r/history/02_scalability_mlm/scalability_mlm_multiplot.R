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
library(fmsb)
library(grid)
library(gridExtra)

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

nOptiRes <- length(data_w[,1]) # Number of optimization resolution
nRowPlot = nOptiRes            # number of rows in the output multi graph
nColPlot = 9      # nLakes     # number of rows in the output multi graph


#---- Defining multiplot lists
plots <- list()

## Reservoir loop here

  ## Optimization resolution loop
  for (i in 1:nOptiRes) {
    
    # To Do: 
    # 1.1 How to convert radarcharts to grobs
    # 2. Multi-plot will be optimization resolution x reservoir i.e. a 5 x 9 matrix
  
    # Generate the plot data
    data <- rbind(data_w[i,], data_wo[i,]) # Bind the results from w/wo reservoirs
    colnames(data) <- paste( sprintf(data_src_wo[,1],fmt = '%#.2f'),"\u00B0",sep=" ") # retain two digits for resolution and add as column names to data frame
    nAppRes <- length(data[1,]) # get the number of corners for the radar plot
    rownames(data) <- c("with reservoir", "wo reservoir") # get the names for the plots in comparison
    data <- rbind(rep(1,nAppRes) , rep(0,nAppRes) , data) # To use the fmsb package, add the max and min rows to show on the plot!
    
    
    # Color vector #0,0.63,1
    colors_border=c( rgb(1,0.57,0,0.9), rgb(0.36,0.36,0.36,0.9) )
    colors_in=c( rgb(1,0.57,0,0.4), rgb(0.36,0.36,0.36,0.7) )
    
    
    # par( mar = c(2, 2, 2, 2))
    # RadarChart !
    print(i)
    xplot <- radarchart( data  , axistype=1 , 
                #custom polygon
                pcol=colors_border , pfcol=colors_in , plwd=4 , plty=1,
                #custom the grid
                cglcol="grey", cglty=1, axislabcol="black", caxislabels=seq(0,1,0.2), cglwd=0.8, seg = 5,
                #custom labels
                vlcex=1.2, calcex=1
    )
  
    # # Annotate title
    # xplot <- xplot + text(x=-1.3, y=1.2, pos=4, labels = 'Tr\u00E9s Marias', cex=1.4 )
    # xplot <- xplot + text(x=-1.3, y=1.05, pos=4, labels = colnames(data)[i], cex=1.4 )
    # 
    # # Add a legend
    # legend(x=0.4, y=1.2, legend = rownames(data[-c(1,2),]), bty = "n", pch=15 , col=colors_in , text.col = "black", cex=1.2, pt.cex=2)

    # Append to multiplot
    # xplot = grob(xplot)
    plots[[i]] <- xplot
    
  } # optimization resolution loop


# Defining the layout of the multiplot
xlay <- matrix(c(1:nOptiRes), nRowPlot, 1, byrow = TRUE)
# xlay <- matrix(c(1:(nOptiRes*nLakes)), nRowPlot, nColPlot, byrow = TRUE)

select_grobs <- function(lay) {
  id <- unique(c(t(lay))) 
  id[!is.na(id)]
}


# Output
pdf("scalability_radar_multiplot.pdf")
grid.arrange(grobs=plots[select_grobs(xlay)], layout_matrix=xlay, 
             top = textGrob("\n Model performance and scalability of mHM with mLM \n", 
                            gp=gpar(fontsize=20,font="Helvetica", just="left")))

# Close PDF
dev.off()