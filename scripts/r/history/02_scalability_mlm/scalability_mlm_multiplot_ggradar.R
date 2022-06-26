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
library(gridExtra)




# Set the path, lake names
ipath = "/Users/shresthp/Nextcloud/Cloud/macbook/01_work/R/scripts/02_scalability_mlm/"
setwd(ipath)
abbrLakes = c("TMA", "SOB", "ITA", "ORO", "CAS", "ARG", "COR", "CLA", "ERI")
nameLakes = c("Tr\u00E9s Marias", "Sobradinho", "Itaparica", "Or\u00F3s", "Castanh\u00E3o",
                "Armando Ribeiro Gon\u00E7alves", "Coremas", "Lake St. Clair", "Lake Erie")

nLakes = length(nameLakes) # number of lakes





#---- Defining multiplot lists
plots <- list()


## RESERVOIR LOOP HERE
for (j in 1:nLakes) {
  

  # Reading the files, preparing the dfs
  file_w = paste("with_mlm_", abbrLakes[j],sep="") # file with mlm metrics
  file_wo = paste("wo_mlm_", abbrLakes[j],sep="")  # file w/o mlm metrics
  
  data_src_w = data.frame(read.delim(file_w, header = TRUE, sep = ","))  # read the data excluding the first header row of optimization scale
  data_w <- as.data.frame(data_src_w[,-1]) # convert to data frame, excluding the first header column of application scale
  
  data_src_wo = data.frame(read.delim(file_wo, header = TRUE, sep = ","))  # read the data excluding the first header row of optimization scale
  data_wo <- as.data.frame(data_src_wo[,-1]) # convert to data frame, excluding the first header column of application scale
  
  nOptiRes <- length(data_w[,1]) # Number of optimization resolution
  nRowPlot = nOptiRes            # number of rows in the output multi graph
  nColPlot = nLakes              # number of cols in the output multi graph


  ## OPTI LOOP HERE
  for (i in 1:nOptiRes) {
    
    # To Do: 
    # 1.1 How to convert radarcharts to grobs
    # 2. Multi-plot will be optimization resolution x reservoir i.e. a 5 x 9 matrix
  
    # Generate the plot data
    data <- rbind(data_w[i,], data_wo[i,]) # Bind the results from w/wo reservoirs
    colnames(data) <- paste( sprintf(data_src_wo[,1],fmt = '%#.2f'),"\u00B0",sep=" ") # retain two digits for resolution and add as column names to data frame
    nAppRes <- length(data[1,]) # get the number of corners for the radar plot
    data <- cbind(c("with mlm", "w/o mlm"), data) # get the names for the plots in comparison
    
    
    # Conditional Transparancy <temporary for paper storyine concept figure>
    if(j == 1){
      # show colors
      opacity1 = 0.9
      opacity2 = 0.6
    } else {
      # no colors
      opacity1 = 0
      opacity2 = 0
    }
    
    if(i == 1){
      # show title
      titlePlot <- nameLakes[j]
    } else {
      # no title
      titlePlot <- " "
    }
    
    
    # Color vector
    colors_border=c( rgb(1,0.57,0,opacity1), rgb(0.36,0.36,0.36,opacity1) )
    colors_in=c( rgb(1,0.57,0,opacity2), rgb(0.36,0.36,0.36,opacity2) )
    
    
    print(paste("plot", i + (j-1) * nOptiRes, sep = " "))
    # Radar Plot
    xplot <- ggradar(data,
            
            # Grid
            grid.min = 0,
            grid.max = 1,
            
            # Labels
            gridline.label.offset = -0.1,
            grid.label.size = 8,
            axis.label.offset = 1.2,
            axis.label.size = 7,
            
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
            plot.title = titlePlot
            
    ) + theme(plot.title = element_text(size = 26, hjust = 0.5, margin = margin(t=0, r=0, b=50, l=0, unit = "pt")))
      
    if( (i == 1) & (j == 1) ){
      
      # Annotate legend
      xplot <- xplot + 
        annotate("segment", x = 0.8, xend = 1, y = 1.3, yend = 1.3, color=colors_border[1], size=3) +
        annotate("segment", x = 0.8, xend = 1, y = 1, yend = 1, color=colors_border[2], size=3) +
        annotate("text", x = 1.45, y = 1.3, label = 'with mLM', size = 6) +
        annotate("text", x = 1.45, y = 1, label = 'w/o mLM', size = 6)
    }
    
    # Annotate opti resolution info
    xplot <- xplot + 
      annotate("rect", xmin = -1.65, xmax = -0.9, ymin = 0.8, ymax = 1.2, alpha = .2) +
      annotate("text", x = -1.25, y = 1, label =  colnames(data)[i+1], size = 8 )
    # Append to multiplot 
    xplot <- ggplotGrob(xplot)
    plots[[i + (j-1) * nOptiRes]] <- xplot
    
  } # optimization resolution loop
  
} # lakes loop


# Defining the layout of the multiplot
# xlay <- matrix(c(1:nOptiRes), nRowPlot, 1, byrow = TRUE)
xlay <- matrix(c(1:(nOptiRes*nLakes)), nRowPlot, nColPlot, byrow = FALSE)

select_grobs <- function(lay) {
  id <- unique(c(lay)) 
  id[!is.na(id)]
}


# Output
pdf("scalability_radar_multiplot_ggradar.pdf", width = 6*nColPlot, height = 5*nRowPlot) # each subplot is 5x5 inches
grid.arrange(grobs=plots[select_grobs(xlay)], layout_matrix=xlay) 

# Close PDF
dev.off()