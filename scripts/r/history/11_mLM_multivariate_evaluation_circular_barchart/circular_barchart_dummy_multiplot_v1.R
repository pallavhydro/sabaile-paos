# library
library(tidyverse)
library(gridExtra)  # for using "grid.arrange" function

# Reference: https://www.r-graph-gallery.com/circular-barplot.html
# by Yan Holtz


# IO
opath = "/Users/shresthp/Nextcloud/Cloud/macbook/01_work/R/scripts/11_mLM_multivariate_evaluation_circular_barchart/"
setwd(opath)


# Create dataset
nameLakes <- c("Tr\u00E9s Marias", "Sobradinho", "Itaparica", "Or\u00F3s", "Castanh\u00E3o",
  "AR Gon\u00E7alves", "Coremas", "Lake St. Clair", "Lake Erie")
nameLakes <- c(rbind(nameLakes,NA)) # Adding alternating NAs for validation metric. 
                                    # The ones with names are for calibration metric.


#---- Defining multiplot lists
plots <- list()
title_eval <- c("\nQ-h-E calibration", "\nQ calibration", "\nh calibration", "\nE calibration",
                "\nQ-h calibration", "\nh-E calibration", "\nQ-E calibration")
nEval <- length(title_eval)
nColPlot <- 5
nRowPlot <- 2


## EVALUATION LOOP HERE
for (i in 1:nEval) {
  
  
  data <- data.frame(
    individual=rep(nameLakes, 3),
    group=c( rep('Streamflow', 18), rep('Water elevation', 18), rep('Evaporation', 18)) ,
    value=sample( seq(0,1,0.01), 54, replace=T)
  )
  
  # Set a number of 'empty bar' to add at the end of each group
  empty_bar <- 2
  to_add <- data.frame( matrix(NA, empty_bar*nlevels(data$group), ncol(data)) )
  colnames(to_add) <- colnames(data)
  to_add$group <- rep(levels(data$group), each=empty_bar)
  data <- rbind(data, to_add)
  data <- data %>% arrange(group)
  data$id <- seq(1, nrow(data))
  
  # Create a copy of data with validation metric set to NA
  data_overlap <- data
  data_overlap <- within(data_overlap, value[is.na(individual)] <- NA)
  
  
  # Get the name and the y position of each label
  label_data <- data
  number_of_bar <- nrow(label_data)
  angle <- 90 - 360 * (label_data$id-0.5) /number_of_bar     # I substract 0.5 because the letter must have the angle of the center of the bars. Not extreme right(1) or extreme left (0)
  label_data$hjust <- ifelse( angle < -90, 1, 0)
  label_data$angle <- ifelse(angle < -90, angle+180, angle)
  
  # prepare a data frame for base lines
  base_data <- data %>% 
    group_by(group) %>% 
    summarize(start=min(id), end=max(id) - empty_bar) %>% 
    rowwise() %>% 
    mutate(title=mean(c(start, end)))
  
  # Plot manipulation setup
  if (i == 1){
    font_scaling = 1.7
  } else {
    font_scaling = 1
  }
  
  # Make the plot
  xplot <- ggplot(data, aes(x=as.factor(id), y=value, fill=group)) +       # Note that id is a factor. If x is numeric, there is some space between the first bar
    
    geom_bar(aes(x=as.factor(id), y=value, fill=group), stat="identity", alpha=0) +
    
    # Add a val=100/75/50/25 lines. I do it at the beginning to make sur barplots are OVER it.
    geom_segment(x = 0.25, y = 1, xend = 58.5, yend = 1, colour = "grey90", size=0.3) +
    geom_segment(x = 0.25, y = 0.8, xend = 58.25, yend = 0.8, colour = "grey90", size=0.3) +
    geom_segment(x = 0.25, y = 0.6, xend = 58, yend = 0.6, colour = "grey90", size=0.3) +
    geom_segment(x = 0.25, y = 0.4, xend = 58, yend = 0.4, colour = "grey90", size=0.3) +
    geom_segment(x = 0.25, y = 0.2, xend = 57.75, yend = 0.2, colour = "grey90", size=0.3) +
    
    # Add text showing the value of each 100/75/50/25 lines
    annotate("text", x = rep(max(data$id),5), y = c(0.2, 0.4, 0.6, 0.8, 1), 
             label = c("0.2", "0.4", "0.6", "0.8", "1") , color="grey", size=3*font_scaling , angle=0, 
             fontface="bold", hjust=1) +
    
    geom_bar(aes(x=as.factor(id), y=value, fill=group), stat="identity", alpha=0.8) +
    geom_bar(data = data_overlap, # overlapping without validation metrics to make cal-val visually distinguishable
             aes(x=as.factor(id), y=value, fill=group), stat="identity", alpha=1) + 
    ylim(-0.75,1.2) +
    theme_minimal() +
    labs(title = title_eval[i]) +
    theme(
      legend.position = "none",
      axis.text = element_blank(),
      axis.title = element_blank(),
      panel.grid = element_blank(),
      plot.title = element_text(size = 25),
      plot.margin = unit(rep(0,4), "cm") 
    ) +
    coord_polar() + 
    geom_text(data=label_data, aes(x=id, y=value+0.1, label=individual, hjust=hjust), 
              color="black", fontface="bold",alpha=0.6, size=3*font_scaling, 
              angle= label_data$angle, inherit.aes = FALSE ) +
    
    # Add base line information
    geom_segment(data=base_data, aes(x = start, y = -0.05, xend = end, yend = -0.05), 
                 colour = "black", alpha=0.8, size=0.6 , inherit.aes = FALSE )  +
    geom_text(data=base_data, aes(x = title, y = -0.18, label=group), vjust=c(2,-0.5,2.5), 
              hjust=c(0.5,0.4,0.5), colour = "black", alpha=0.8, size=3*font_scaling, 
              fontface="bold", angle= c(310,10,70), inherit.aes = FALSE)

  # Append to multiplot 
  xplot <- ggplotGrob(xplot)
  plots[[i]] <- xplot

} # EVALUTAION LOOP ENDS


# Defining the layout of the multiplot
xlay <- matrix(c(1,1,2,3,4,1,1,5,6,7), nRowPlot, nColPlot, byrow = TRUE)

select_grobs <- function(lay) {
  id <- unique(c(t(lay))) # transpose ON if byrow = TRUE in xlay! If not, remove transpose!
  id[!is.na(id)]
}


# Output
pdf("multivariate_evaluation_circular_barchart.pdf", width = 5*nColPlot, height = 5*nRowPlot) # each subplot is 5x5 inches
grid.arrange(grobs=plots[select_grobs(xlay)], layout_matrix=xlay)

# Close PDF
dev.off()
