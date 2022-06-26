#####################################################################################
##                   ----------------------------------------------------------------
## ==================== Dam commission and Data availability plots
##                   ----------------------------------------------------------------
## --- Code developer: 
## ------------------  Pallav Kumar Shrestha pallav-kumar.shrestha@ufz.de ------
## ------------------  02 Oct 2021 ---------------------------------------------
##
## --- Mods: 
##          xx xxx xxxx - xxx
#####################################################################################


# Open libraries/ packages
library(ggplot2)
library(reshape) # for melt
library(gridExtra)  # for using "grid.arrange" function



# ====================== CONTROL

# File names, paths
lut_file= "/Users/shresthp/tmp/Win7/global_mlm/selection/atable_mlm_global_dam_selection_v1_tm_adj_v3.csv"
fNameout_damcomm_dataavail = "dam_commission_data_availability.pdf"
sim_dir = "/Users/shresthp/git/GitLab/pallavshrestha/papers/mlm_intro_scalability/figures_v2"

# Graph parameters
hist_clr <- "blue"
frequency_upper_limit <- 15
era5_start_year <- 1950
era5_end_year <- 2018
year_lower_limit <- 1900
year_upper_limit <- 2020

# Defining MULTIPLOT lists
plots <- list()
nColPlot <- 3
nRowPlot <- 1




# ====================== READ
# Read LUT file
lut_data <- read.delim(lut_file, sep = "," , header = TRUE )
lut_data[lut_data == '-9999'] <- NA
ndomains = length(lut_data$station_id)




# ====================== PROCESS

# Select and store from LUT
data <- as.data.frame(cbind(lut_data$YEAR, lut_data$d_start, lut_data$d_end))
colnames(data) <- c('dam_commission', 'gauge_start', 'gauge_end')
data[data == '-9999'] <- NA
dam_names <- as.character(lut_data$DAM_NAME)




# ====================== GRAPH

# ------------------  Histogram - Year of Dam Commission
main <- ggplot() +
  # Histogram
  geom_histogram(data = lut_data, aes(x = lut_data$YEAR), color=hist_clr, fill=hist_clr, alpha=0.6, bins = 20) +
  # ERA5 data availability years
  annotate("rect", xmin = era5_start_year, xmax = era5_end_year, ymin = 0, ymax = frequency_upper_limit, fill = "black", alpha = 0.3) +
  annotate("text", 
           x = year_lower_limit + 0.95 * (year_upper_limit - year_lower_limit), 
           y = 0.7 * frequency_upper_limit,  cex = 5, 
           label = "ERA5 window", colour = "black") +
  
  
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
  
  scale_x_continuous(name = "Year of Dam Commission", limits = c(year_lower_limit, year_upper_limit),
                     breaks = c(seq(year_lower_limit, year_upper_limit, 20)),
                     sec.axis = dup_axis(name ="", labels = c()))

# Append to multiplot 
xplot <- ggplotGrob(main)
plots[[1]] <- xplot 



# ------------------  Histogram - Start Year of Gauge Data Availability
main <- ggplot() +
  # Histogram
  geom_histogram(data = lut_data, aes(x = lut_data$d_start), color=hist_clr, fill=hist_clr, alpha=0.6, bins = 20) +
  # ERA5 data availability years
  annotate("rect", xmin = era5_start_year, xmax = era5_end_year, ymin = 0, ymax = frequency_upper_limit, fill = "black", alpha = 0.3) +
  annotate("text", 
           x = year_lower_limit + 0.95 * (year_upper_limit - year_lower_limit), 
           y = 0.7 * frequency_upper_limit,  cex = 5, 
           label = "ERA5 window", colour = "black") +
  
  
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
  
  scale_x_continuous(name = "Start Year of Gauge Data", limits = c(year_lower_limit, year_upper_limit),
                     breaks = c(seq(year_lower_limit, year_upper_limit, 20)),
                     sec.axis = dup_axis(name ="", labels = c()))

# Append to multiplot 
xplot <- ggplotGrob(main)
plots[[2]] <- xplot 



# ------------------  Histogram - End Year of Gauge Data Availability
main <- ggplot() +
  # Histogram
  geom_histogram(data = lut_data, aes(x = lut_data$d_end), color=hist_clr, fill=hist_clr, alpha=0.6, bins = 20) +
  # ERA5 data availability years
  annotate("rect", xmin = era5_start_year, xmax = era5_end_year, ymin = 0, ymax = frequency_upper_limit, fill = "black", alpha = 0.3) +
  annotate("text", 
           x = year_lower_limit + 0.7 * (year_upper_limit - year_lower_limit), 
           y = 0.7 * frequency_upper_limit,  cex = 5, 
           label = "ERA5 window", colour = "black") +
  
  
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
  
  scale_x_continuous(name = "End Year of Gauge Data", limits = c(year_lower_limit, year_upper_limit),
                     breaks = c(seq(year_lower_limit, year_upper_limit, 20)),
                     sec.axis = dup_axis(name ="", labels = c()))

# Append to multiplot 
xplot <- ggplotGrob(main)
plots[[3]] <- xplot 



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
pdf(paste(sim_dir, fNameout_damcomm_dataavail, sep="/"), width = 4*nColPlot, height = 5.5*nRowPlot)

grid.arrange(grobs=plots[select_grobs(xlay)], layout_matrix=xlay)

# Close PDF
dev.off()

