######################################################################################################### 
##                            ---------------------------------------------------------------------------
## ========================== Boxplot
##                            ----------------------------------------------------------------------------
## ---------- Code developer: 
## -------------------------  Pallav Kumar Shrestha pallav-kumar.shrestha@ufz.de ------
## -------------------------  09 March 2021 ----------------------------------------
#########################################################################################################




# Open libraries/ packages
library(ggplot2)
library(scales) # pretty_breaks



plot_boxplot <- function(array, path, fNameout, xhead, grouphead, groupcolors, grouplabels, xtitle, ytitle, xlabels, ylimits){
  
  
  # Plotting the graph
  
  main <- ggplot(data = array, aes( x= factor(xhead), y = value, color = factor(grouphead))) +
    # Box plot
    geom_boxplot(fill = "white", width=2/length(unique(xhead)), outlier.fill = "white", outlier.shape = 21) +
    # Data points
    # geom_jitter(fill="black", size=0.4, alpha=0.2) +
    
    scale_color_manual(values = groupcolors, labels = grouplabels) +
        
    theme(
      text=element_text(family = "Helvetica", colour = "black"),
      axis.ticks.length=unit(-0.2, "cm"),
      axis.ticks = element_line(colour = "black", size = 0.5),
      axis.text.x = element_text(size=12, colour = "black", angle = 90, hjust = c(1)),
      axis.title.x = element_text(size=15, margin = margin(t = 10), colour = "black"),
      axis.text.y.left = element_text(size=12, margin = margin(r = 10), colour = "black"),
      axis.text.y.right = element_text(size=12, margin = margin(l = 10), colour = "black"),
      axis.title.y.left  = element_text(size=15, margin = margin(r = 15), colour = "black", hjust = c(0.5)),
      axis.title.y.right = element_text(size=15, margin = margin(l = 15), colour = "black", hjust = c(0.5)),
      plot.title = element_blank(),
      panel.border = element_rect(colour = "black", fill=NA, size=1),
      panel.background = element_blank(),
      panel.grid.major = element_line(colour = alpha("black", 0.5), size=0.2, linetype = 3),
      legend.position = "top",
      legend.direction = "horizontal",
      legend.key.width = unit(0.5, "cm"),
      legend.title = element_blank(),
      legend.background = element_blank()) +
    
    scale_x_discrete(name = xtitle, labels = xlabels) +
    
    scale_y_continuous(name = ytitle, breaks=pretty_breaks(n = 5), sec.axis = dup_axis(labels = c(), name = "") ) +
    
    guides(color = guide_legend(nrow = 1, label.position = "bottom")) +
    
    coord_cartesian(ylim = ylimits)

  # Output
  ggsave(main, file=paste(path, fNameout , sep="/"), width = 8, height = 6, units = "in", dpi = 300)
  
}

