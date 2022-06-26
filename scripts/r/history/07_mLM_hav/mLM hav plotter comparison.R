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

jpeg(paste(iopath3,".area.jpg",sep=""), width=8, height=4, units = "in", res = 300)

ggplot(import, aes(x=import[,1])) + geom_line(aes(y=import[,2], color = "h-A curve DEM"), size = 2) +
  geom_line(data=import2, aes(x=import2[,1], y=import2[,2], color = "h-A curve ANA+DEM"), size = 2) +
  geom_point(data=import3, aes(x=import3[,1], y=import3[,2], color = "h-A points ANA"), size = 2) +
  # geom_line(aes(y=import[,4]/20, color = "h-V curve"), size = 2) +
  ggtitle("Stage Area (ha) relationship [Tres Marias Reservoir]") +
  ylab(expression(paste("Lake Surface Area, A [",km^{2},"]"))) + xlab("Stage, h [masl]") +
  scale_colour_manual("", values = c("h-A curve ANA+DEM"="blue", "h-A curve DEM"="red", "h-A points ANA"="black")) +
  theme(plot.title = element_text(size = 10, face = "bold", hjust = 0.5), text=element_text(family = "Helvetica"), axis.ticks.length=unit(-0.25, "cm"), axis.text.x = element_text(margin = margin(t = 10)),
        axis.text.y = element_text(margin = margin(r = 10)),  
        axis.title.y = element_text(margin = margin(r = 10)),
        axis.title.x = element_text(margin = margin(t = 10)), panel.border = element_rect(colour = "black", fill=NA, size=1),
        panel.background = element_blank(), legend.position = c(0.1, 1),legend.justification = c(0, 1), 
        legend.background = element_rect(fill=alpha('white', 0))) +
  scale_x_continuous(minor_breaks = seq(510 , 600, 10), breaks = seq(520, 600, 20), limits = c(510,600)) +
  scale_y_continuous(limits = c(0,2000)) 

dev.off()


# Creating the plot

jpeg(paste(iopath3,".volume.jpg",sep=""), width=8, height=4, units = "in", res = 300)

ggplot(import, aes(x=import[,1])) + geom_line(aes(y=import[,4], color = "h-V curve DEM"), size = 2) +
  geom_line(data=import2, aes(x=import2[,1], y=import2[,4], color = "h-V curve ANA+DEM"), size = 2) +
  geom_point(data=import3, aes(x=import3[,1], y=import3[,4], color = "h-V points ANA"), size = 2) +
  # geom_line(aes(y=import[,4]/20, color = "h-V curve"), size = 2) +
  ggtitle("Stage Volume (hv) relationship [Tres Marias Reservoir]") +
  ylab(expression(paste("Lake Volume, V [mcm]"))) + xlab("Stage, h [masl]") +
  scale_colour_manual("", values = c("h-V curve ANA+DEM"="blue", "h-V curve DEM"="red", "h-V points ANA"="black")) +
  theme(plot.title = element_text(size = 10, face = "bold", hjust = 0.5), text=element_text(family = "Helvetica"), axis.ticks.length=unit(-0.25, "cm"), axis.text.x = element_text(margin = margin(t = 10)),
        axis.text.y = element_text(margin = margin(r = 10)),  
        axis.title.y = element_text(margin = margin(r = 10)),
        axis.title.x = element_text(margin = margin(t = 10)), panel.border = element_rect(colour = "black", fill=NA, size=1),
        panel.background = element_blank(), legend.position = c(0.1, 1),legend.justification = c(0, 1), 
        legend.background = element_rect(fill=alpha('white', 0))) +
  scale_x_continuous(minor_breaks = seq(510 , 600, 10), breaks = seq(520, 600, 20), limits = c(510,600)) +
  scale_y_continuous(limits = c(0,40000)) 

dev.off()




