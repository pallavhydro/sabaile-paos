#####################################################################################
##                   ----------------------------------------------------------------
## ==================== EVA plot with DCL values
##                   ----------------------------------------------------------------
## --- Code developer: 
## ------------------  Pallav Kumar Shrestha pallav-kumar.shrestha@ufz.de ------
## ------------------  26 Aug 2021 ---------------------------------------------
##
## --- Mods: 
##          xx XXX 2021 - 
#####################################################################################


# Open libraries/ packages
library(ggplot2)
library(reshape) # for melt



# General control parameters
fNameOut = "check_EVA_and_DCL.jpg"




# ====================== DATA
# Read file

dcl_data <- read.delim(dir(pattern='_check_EVA_and_DCL.out')[1], sep = ":" , header = FALSE, nrows = 5 )
eva_data <- read.delim(dir(pattern='_check_EVA_and_DCL.out')[1], sep = "" , header = FALSE, skip = 5 )



# ====================== GRAPH

# Get domain id from path
path = getwd()
pathsplit = unlist(strsplit(path, "/"))
domainid = pathsplit[length(pathsplit)-1] # domain ID is the penultimate directory

# # Prepare x-axis 
# dayBreaks <- c(seq(-nDays_prior, nDays + nLead - 1, 5))
# dayLabels <- c(seq(dStart - nDays_prior , dEnd + nLead, 5))
# dayLabels <- c("", dayLabels[2:length(dayLabels)])


# ==========================
# EVA Plot
# ==========================
main <- ggplot() +
  # EA plot
  geom_line(data = eva_data, aes( x = V1, y = V2), color = "black", linetype = 1, size = 1) +
  # DCL Area dem
  geom_hline(yintercept = dcl_data[2,2], linetype = 2, size = 0.5, color = "blue") +
  # DCL Area EVA
  geom_hline(yintercept = dcl_data[3,2], linetype = 2, size = 0.5, color = "red") +
  # DCL input/ estimate
  geom_vline(xintercept = dcl_data[1,2], linetype = 2, size = 0.5, color = "blue") +
  annotate("text", x = dcl_data[1,2]-0.1*(dcl_data[1,2]-min(eva_data$V1)), y = 0.5*max(eva_data$V2),  cex = 4, 
           label = format(paste(dcl_data[1,2],  sep = "")), colour = "black") +

  ggtitle(domainid) +
  
  theme(
    text=element_text(family = "Helvetica", colour = "black"),
    axis.ticks.length=unit(-0.1, "cm"), 
    axis.ticks = element_line(colour = "black", size = 0.1),
    axis.text.x = element_text(size=8, margin = margin(t = 5), colour = "black"), 
    axis.title.x = element_text(size=10, margin = margin(t = 10), colour = "black"),
    axis.text.y.left  = element_text(size=8, margin = margin(r = 5), colour = "black"), 
    axis.text.y.right = element_text(size=8, margin = margin(l = 5), colour = "black"), 
    axis.title.y.left  = element_text(size=10, margin = margin(r = 5), colour = "black", hjust = c(0.5)), 
    axis.title.y.right = element_text(size=10, margin = margin(l = 10), colour = "black", hjust = 0), 
    plot.title = element_text(size = 10, colour = "blue"),
    panel.border = element_rect(colour = "black", fill=NA, size=0.5),
    panel.background = element_blank(),
    panel.grid = element_blank(),
    legend.position = 'none') +
  
  scale_y_continuous(name = expression(paste("Reservoir Surface Area (",km^{2},")", sep = ""))) +
  
  scale_x_continuous(name = "Reservoir Elevation (masl)")
  
# Output
ggsave(main, file=paste(fNameOut, sep=""), width = 6, height = 4.5, units = "in", dpi = 300)


