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
fName = "dds_results.out"



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
  
  # Reading the optimization file
  data = data.frame(read.delim(paste(iopath,fName,sep=""), skip = 7, header=FALSE, sep = ""))  # reading all the data
  data <- data[,1:2] # Storing only iteration count and OF
  nIte <- length(data[,1])    # count number of iterations on the file
  
  
  
  main <- ggplot(data, aes(x=data[,1])) + geom_line(aes(y=data[,2]), color = "chartreuse3") +
    ggtitle("OF evolution") + 
    ylab(expression(paste("Objective Function"))) + xlab("Iteration count") +
    labs(subtitle = subtitle_text) +
    theme(legend.position = "none",
          title = element_text(family = "Helvetica", size = 10), axis.ticks.length=unit(-0.25, "cm"), axis.text.x = element_text(size=10, margin = margin(t = 10)),
          axis.text.y = element_text(size=10, margin = margin(r = 10)), axis.title.y = element_text(size=10, margin = margin(r = 10)),
          axis.title.x = element_text(size=10, margin = margin(t = 20)), panel.border = element_rect(colour = "black", fill=NA, size=1),
          panel.background = element_blank(), plot.subtitle = element_text(size = 14, face = "bold", hjust = c(1,1))) +
    scale_y_continuous(sec.axis = dup_axis(name ="", labels = c()), expand = c(0,0)) +
    expand_limits(y=0)
  
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
pdf(paste(iopath_parent,fName,".",bName,".pdf",sep=""), width=4*nColPlot, height=3*nRowPlot)

grid.arrange(grobs=plots[select_grobs(xlay)], layout_matrix=xlay)

# Close PDF
dev.off()


