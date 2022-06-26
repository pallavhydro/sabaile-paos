######################################################################################################### 
##                            ---------------------------------------------------------------------------
## ========================== Preprocessing tool for plotting Stage Area Volume (hav) relationship for mLM
##                            ----------------------------------------------------------------------------
## ---------- Code developer: 
## -------------------------  Pallav Kumar Shrestha pallav-kumar.shrestha@ufz.de ------
## -------------------------  23 March 2018 ----------------------------------------
#########################################################################################################

## -------------------------------------------------------------------------------
## The beginning 
## -------------------------------------------------------------------------------

# Open libraries/ packages
library(ggplot2)
library(gridExtra)
library(xts)
library(zoo)
library(lattice)
library(latticeExtra)
library(grid)
library(stringr)
library(broom)
library(dplyr)


# Set the IO path
iopath = "/Users/shresthp/tmp/eve_f2_home/home/shresthp/projects/mLM_development/01_hav_from_dem/hav/lake_00123.hav"  # for Mac runs
iopath2 = "/Users/shresthp/tmp/eve_f2_home/home/shresthp/projects/mLM_development/02_lake_wb_simple/lake_00001.hav"
iopath3 = "/Users/shresthp/tmp/eve_f2_home/home/shresthp/projects/mLM_development/02_lake_wb_simple/backup/lake_00001_ANA.hav"

# Read the hav file
import <-read.table(iopath, skip = 2, col.names = c("stage", "area", "vol_slice", "volume"))
import2 <-read.table(iopath2, skip = 2, col.names = c("stage", "area", "vol_slice", "volume"))
import3 <-read.table(iopath3, skip = 2, col.names = c("stage", "area", "vol_slice", "volume"))

# Creating the plot

opath = "/Users/shresthp/tmp/eve_f2_home/home/shresthp/projects/mLM_development/02_lake_wb_simple/EGU18/"

jpeg(paste(opath,"TM_hav_curve_EGU18.jpg",sep=""), width=16, height=6, units = "in", res = 150)

ggplot(import, aes(x=import[,1])) +
  # geom_line(aes(y=import[,2], color = "h-A curve DEM"), size = 2) +
  geom_line(data=import2, aes(x=import2[,1], y=import2[,2], color = "h-A curve ANA+DEM"), size = 2) +
  geom_line(data=import2, aes(x=import2[,1], y=import2[,4]/20, color = "h-V curve ANA+DEM"),  size = 2) +
  geom_point(data=import3, aes(x=import3[,1], y=import3[,2], color = "h-A points ANA"), size = 4) +
  geom_point(data=import3, aes(x=import3[,1], y=import3[,4]/20, color = "h-V points ANA"), size = 4) +
  # geom_line(aes(y=import[,4]/20, color = "h-V curve"), size = 2) +
  ggtitle("Stage Area (ha) relationship") +
  ylab(expression(paste("Lake Surface Area, A [",km^{2},"]"))) + xlab("Stage, h [masl]") +
  scale_colour_manual("", values = c("h-A curve ANA+DEM"="indianred3", "h-A points ANA"="black", "h-V curve ANA+DEM"="steelblue3", "h-V points ANA"="blue")) +
  theme(plot.title = element_text(size = 24, hjust = 0.5), text=element_text(family = "Helvetica"), 
        axis.ticks.length=unit(-0.25, "cm"), axis.text.x = element_text(size = 20,margin = margin(t = 10)),
        axis.text.y = element_text(size = 20, margin = margin(r = 10)),  axis.text.y.right = element_text(margin = margin(l = 10)), 
        axis.title.y = element_text(size = 24,margin = margin(r = 10)), axis.title.y.right = element_text(margin = margin(l = 10), angle = 90),
        axis.title.x = element_text(size = 24,margin = margin(t = 10)), panel.border = element_rect(colour = "black", fill=NA, size=1),
        panel.background = element_blank(), legend.position = c(0.1, 1),legend.justification = c(0, 1), 
        legend.background = element_rect(fill=alpha('white', 0)), legend.text = element_text(size = 24),
        legend.key.size = unit(3, 'lines')) +
  scale_x_continuous(breaks = seq(525, 600, 25), limits = c(525,600)) +
  scale_y_continuous(sec.axis = sec_axis(~.*20, name = "Lake Volume, V [mcm]"), limits = c(0,2000)) 

dev.off()


# Creating the plot

# jpeg(paste(opath,".volume.jpg",sep=""), width=8, height=2.5, units = "in", res = 150)

# ggplot(import, aes(x=import[,1])) + 
#   # geom_line(aes(y=import[,4], color = "h-V curve DEM"), size = 2) +
#   geom_line(data=import2, aes(x=import2[,1], y=import2[,4], color = "h-V curve ANA+DEM"), size = 2) +
#   geom_point(data=import3, aes(x=import3[,1], y=import3[,4], color = "h-V points ANA"), size = 2) +
#   # geom_line(aes(y=import[,4]/20, color = "h-V curve"), size = 2) +
#   ggtitle("Stage Volume (hv) relationship") +
#   ylab(expression(paste("Lake Volume, V [mcm]"))) + xlab("Stage, h [masl]") +
#   scale_colour_manual("", values = c("h-V curve ANA+DEM"="red", "h-V points ANA"="black")) +
#   theme(plot.title = element_text(size = 24, face = "bold", hjust = 0.5), text=element_text(size = 14, family = "Helvetica"), 
#         axis.ticks.length=unit(-0.25, "cm"), axis.text.x = element_text(margin = margin(t = 10)),
#         axis.text.y = element_text(margin = margin(r = 10)),  
#         axis.title.y = element_text(margin = margin(r = 10)),
#         axis.title.x = element_text(margin = margin(t = 10)), panel.border = element_rect(colour = "black", fill=NA, size=1),
#         panel.background = element_blank(), legend.position = c(0.1, 1),legend.justification = c(0, 1), 
#         legend.background = element_rect(fill=alpha('white', 0))) +
#   scale_x_continuous(minor_breaks = seq(510 , 600, 10), breaks = seq(520, 600, 20), limits = c(510,600)) +
#   scale_y_continuous(limits = c(0,40000)) 

# dev.off()




