#####################################################################################
##                   ----------------------------------------------------------------
## ====================   Plot illustrating the Physiography and Climatology 
##                        Distribution of GRanD resrevoirs
##                   ----------------------------------------------------------------
## --- Code developer: 
## ------------------  Pallav Kumar Shrestha pallav-kumar.shrestha@ufz.de ------
## ------------------  01 Sep 2021 ---------------------------------------------
##
## --- Mods: 
##
#####################################################################################


# Open libraries/ packages
library(ggplot2)
library(reshape) # for melt
library(gridExtra)  # for using "grid.arrange" function


# General control parameters
lut_file= "/Users/shresthp/tmp/Win7/global_mlm/selection/atable_mlm_global_dam_selection_v1_tm_adj_v4.csv"
# sim_dir = "/Users/shresthp/tmp/eve_work/work/shresthp/ecflow_tests/mlm_2021_fork_forward_v1/work/mhm"
sim_dir = "/Users/shresthp/git/GitLab/pallavshrestha/papers/mlm_intro_scalability/figures_v2"
fNameout_phyclimdist = "phyclim_distribution.pdf"


# Graph parameters
hist_clr <- "blue"
frequency_upper_limit = 30

# Defining MULTIPLOT lists
plots <- list()
nColPlot <- 5
nRowPlot <- 1


# ====================== DATA
# Read LUT file
lut_data <- read.delim(lut_file, sep = "," , header = TRUE )
# ca ratio can't be less than 1
lut_data$ds_stn_cr1[lut_data$ds_stn_cr1 < 1] <- 1

ndomains = length(lut_data$station_id)







# ====================== GRAPH

# ------------------  Histogram - Catchment Area at Dam
main <- ggplot() +
  # Histogram
  geom_histogram(data = lut_data, aes(x = lut_data$CATCH_SKM / 1000), color=hist_clr, fill=hist_clr, alpha=0.6, bins = 20) +
  # Min and Max
  annotate("text", x = 0.75 * max(lut_data$CATCH_SKM / 1000), y = 20,  cex = 5, 
           label = paste("min: ", formatC(min(lut_data$CATCH_SKM / 1000), format="f", big.mark=",", digits = 0) ,  sep = ""), colour = "black") +
  annotate("text", x = 0.85 * max(lut_data$CATCH_SKM / 1000), y = 20,  cex = 5, 
           label = paste("max: ", formatC(max(lut_data$CATCH_SKM / 1000), format="f", big.mark=",", digits = 0), sep = ""), colour = "black") +
  
  theme(
    text=element_text(family = "Helvetica", colour = "black"),
    axis.ticks.length=unit(-0.2, "cm"), 
    axis.ticks = element_line(colour = "black", size = 0.5),
    axis.text.x = element_text(size=12, margin = margin(t = 10), colour = "black"), 
    axis.title.x = element_text(size=14, margin = margin(t = 10), colour = "black"),
    axis.text.y.left = element_text(size=12, margin = margin(r = 10), colour = "black"), 
    axis.title.y.left  = element_text(size=14, margin = margin(r = 10, l = 15), colour = "black", hjust = c(0.5)), 
    panel.border = element_rect(colour = "black", fill=NA, size=1),
    panel.background = element_blank(),
    panel.grid.major = element_line(colour = alpha("black", 0.5), size=0.2, linetype = 3),
    legend.position = c(0.3, 0.85),
    legend.title = element_blank(),
    legend.background = element_blank()) +
  
  coord_flip() +
  
  scale_y_continuous(name = "frequency", limits = c(0, frequency_upper_limit),
                     # breaks = seq(metrics_lower_limit,1,0.2), labels = c(seq(metrics_lower_limit,1,0.2)),
                     sec.axis = dup_axis(name ="",  labels = c())) +

  scale_x_continuous(name = expression(paste("c.a. at dam [ x", 10^3, " ", km^2, " ]")), 
                     sec.axis = dup_axis(name ="", labels = c()))

# Append to multiplot 
xplot <- ggplotGrob(main)
plots[[1]] <- xplot 


# ------------------  Histogram - Reservoir volume
main <- ggplot() +
  # Histogram
  geom_histogram(data = lut_data, aes(x = lut_data$CAP_MCM / 1000), color=hist_clr, fill=hist_clr, alpha=0.6, bins = 20) +
  # Min and Max
  annotate("text", x = 0.75 * max(lut_data$CAP_MCM  / 1000), y = 20,  cex = 5, 
           label = paste("min: ", formatC(min(lut_data$CAP_MCM/ 1000 ), format="f", big.mark=",", digits = 3) ,  sep = ""), colour = "black") +
  annotate("text", x = 0.85 * max(lut_data$CAP_MCM  / 1000), y = 20,  cex = 5, 
           label = paste("max: ", formatC(max(lut_data$CAP_MCM/ 1000), format="f", big.mark=",", digits = 0), sep = ""), colour = "black") +
  
  theme(
    text=element_text(family = "Helvetica", colour = "black"),
    axis.ticks.length=unit(-0.2, "cm"), 
    axis.ticks = element_line(colour = "black", size = 0.5),
    axis.text.x = element_text(size=12, margin = margin(t = 10), colour = "black"), 
    axis.title.x = element_text(size=14, margin = margin(t = 10), colour = "black"),
    axis.text.y.left = element_text(size=12, margin = margin(r = 10), colour = "black"), 
    axis.title.y.left  = element_text(size=14, margin = margin(r = 10, l = 15), colour = "black", hjust = c(0.5)), 
    panel.border = element_rect(colour = "black", fill=NA, size=1),
    panel.background = element_blank(),
    panel.grid.major = element_line(colour = alpha("black", 0.5), size=0.2, linetype = 3),
    legend.position = c(0.3, 0.85),
    legend.title = element_blank(),
    legend.background = element_blank()) +
  
  coord_flip() +
  
  scale_y_continuous(name = "frequency", limits = c(0, frequency_upper_limit),
                     # breaks = seq(metrics_lower_limit,1,0.2), labels = c(seq(metrics_lower_limit,1,0.2)),
                     sec.axis = dup_axis(name ="",  labels = c())) +
  
  scale_x_continuous(name = expression(paste("Capacity [ x", 10^9, " ", m^3," ]")), 
                     sec.axis = dup_axis(name ="", labels = c()))

# Append to multiplot 
xplot <- ggplotGrob(main)
plots[[2]] <- xplot 



# ------------------  Histogram - Dam height
main <- ggplot() +
  # Histogram
  geom_histogram(data = lut_data, aes(x = lut_data$DAM_H_m), color=hist_clr, fill=hist_clr, alpha=0.6, bins = 20) +
  # Min and Max
  annotate("text", x = 0.75 * max(lut_data$DAM_H_m), y = 20,  cex = 5, 
           label = paste("min: ", formatC(min(lut_data$DAM_H_m), big.mark=",") ,  sep = ""), colour = "black") +
  annotate("text", x = 0.85 * max(lut_data$DAM_H_m), y = 20,  cex = 5, 
           label = paste("max: ", formatC(max(lut_data$DAM_H_m), big.mark=","), sep = ""), colour = "black") +
  
  theme(
    text=element_text(family = "Helvetica", colour = "black"),
    axis.ticks.length=unit(-0.2, "cm"), 
    axis.ticks = element_line(colour = "black", size = 0.5),
    axis.text.x = element_text(size=12, margin = margin(t = 10), colour = "black"), 
    axis.title.x = element_text(size=14, margin = margin(t = 10), colour = "black"),
    axis.text.y.left = element_text(size=12, margin = margin(r = 10), colour = "black"), 
    axis.title.y.left  = element_text(size=14, margin = margin(r = 10, l = 15), colour = "black", hjust = c(0.5)), 
    panel.border = element_rect(colour = "black", fill=NA, size=1),
    panel.background = element_blank(),
    panel.grid.major = element_line(colour = alpha("black", 0.5), size=0.2, linetype = 3),
    legend.position = c(0.3, 0.85),
    legend.title = element_blank(),
    legend.background = element_blank()) +
  
  coord_flip() +
  
  scale_y_continuous(name = "frequency", limits = c(0, frequency_upper_limit),
                     # breaks = seq(metrics_lower_limit,1,0.2), labels = c(seq(metrics_lower_limit,1,0.2)),
                     sec.axis = dup_axis(name ="",  labels = c())) +
  
  scale_x_continuous(name = "Dam height [ m a.s.l. ]", 
                     sec.axis = dup_axis(name ="", labels = c()))

# Append to multiplot 
xplot <- ggplotGrob(main)
plots[[3]] <- xplot 



# ------------------  Histogram - C.a. ratio
main <- ggplot() +
  # Histogram
  geom_histogram(data = lut_data, aes(x = lut_data$ds_stn_cr1), color=hist_clr, fill=hist_clr, alpha=0.6, bins = 20) +
  # Min and Max
  annotate("text", x = 1 + 0.75 * (max(lut_data$ds_stn_cr1) - 1), y = 20,  cex = 5, 
           label = paste("min: ", formatC(min(lut_data$ds_stn_cr1), big.mark=",") ,  sep = ""), colour = "black") +
  annotate("text", x = 1+ 0.85 * (max(lut_data$ds_stn_cr1) - 1), y = 20,  cex = 5, 
           label = paste("max: ", formatC(max(lut_data$ds_stn_cr1), big.mark=",", format="f", digits = 2), sep = ""), colour = "black") +
  
  theme(
    text=element_text(family = "Helvetica", colour = "black"),
    axis.ticks.length=unit(-0.2, "cm"), 
    axis.ticks = element_line(colour = "black", size = 0.5),
    axis.text.x = element_text(size=12, margin = margin(t = 10), colour = "black"), 
    axis.title.x = element_text(size=14, margin = margin(t = 10), colour = "black"),
    axis.text.y.left = element_text(size=12, margin = margin(r = 10), colour = "black"), 
    axis.title.y.left  = element_text(size=14, margin = margin(r = 10, l = 15), colour = "black", hjust = c(0.5)), 
    panel.border = element_rect(colour = "black", fill=NA, size=1),
    panel.background = element_blank(),
    panel.grid.major = element_line(colour = alpha("black", 0.5), size=0.2, linetype = 3),
    legend.position = c(0.3, 0.85),
    legend.title = element_blank(),
    legend.background = element_blank()) +
  
  coord_flip() +
  
  scale_y_continuous(name = "frequency", limits = c(0, frequency_upper_limit),
                     # breaks = seq(metrics_lower_limit,1,0.2), labels = c(seq(metrics_lower_limit,1,0.2)),
                     sec.axis = dup_axis(name ="",  labels = c())) +
  
  scale_x_continuous(name = "c.a. at station / c.a. at dam", breaks = c(1,1.2,1.5,2), 
                     sec.axis = dup_axis(name ="", labels = c()))

# Append to multiplot 
xplot <- ggplotGrob(main)
plots[[4]] <- xplot 



# ------------------  Histogram - Location latitude
main <- ggplot() +
  # Histogram
  geom_histogram(data = lut_data, aes(x = lut_data$Latitude), color=hist_clr, fill=hist_clr, alpha=0.6, bins = 20) +
  # Min and Max
  annotate("text", x = 0.15 * max(lut_data$Latitude), y = 20,  cex = 5, 
           label = paste("min: ", formatC(min(lut_data$Latitude), big.mark=",", format="f", digits = 0) ,  sep = ""), colour = "black") +
  annotate("text", x = 0.30 * max(lut_data$Latitude), y = 20,  cex = 5, 
           label = paste("max: ", formatC(max(lut_data$Latitude), big.mark=",", format="f", digits = 0), sep = ""), colour = "black") +
  
  theme(
    text=element_text(family = "Helvetica", colour = "black"),
    axis.ticks.length=unit(-0.2, "cm"), 
    axis.ticks = element_line(colour = "black", size = 0.5),
    axis.text.x = element_text(size=12, margin = margin(t = 10), colour = "black"), 
    axis.title.x = element_text(size=14, margin = margin(t = 10), colour = "black"),
    axis.text.y.left = element_text(size=12, margin = margin(r = 10), colour = "black"), 
    axis.title.y.left  = element_text(size=14, margin = margin(r = 10, l = 15), colour = "black", hjust = c(0.5)), 
    panel.border = element_rect(colour = "black", fill=NA, size=1),
    panel.background = element_blank(),
    panel.grid.major = element_line(colour = alpha("black", 0.5), size=0.2, linetype = 3),
    legend.position = c(0.3, 0.85),
    legend.title = element_blank(),
    legend.background = element_blank()) +
  
  coord_flip() +
  
  scale_y_continuous(name = "frequency", limits = c(0, frequency_upper_limit),
                     # breaks = seq(metrics_lower_limit,1,0.2), labels = c(seq(metrics_lower_limit,1,0.2)),
                     sec.axis = dup_axis(name ="",  labels = c())) +
  
  scale_x_continuous(name = "Latitude [deg]", #breaks = c(1,1.2,1.5,2), 
                     sec.axis = dup_axis(name ="", labels = c()))

# Append to multiplot 
xplot <- ggplotGrob(main)
plots[[5]] <- xplot 



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
pdf(paste(sim_dir, fNameout_phyclimdist, sep="/"), width = 3*nColPlot, height = 4*nRowPlot)

grid.arrange(grobs=plots[select_grobs(xlay)], layout_matrix=xlay)

# Close PDF
dev.off()
