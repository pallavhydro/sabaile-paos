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

# Read the hav file
import <-read.table(iopath, skip = 2, col.names = c("stage", "area", "vol_slice", "volume"))
import2 <-read.table(iopath2, skip = 2, col.names = c("stage", "area", "vol_slice", "volume"))

# Creating the plot

jpeg(paste(iopath,".jpg",sep=""), width=8, height=4, units = "in", res = 300)

ggplot(import, aes(x=import[,1])) + geom_line(aes(y=import[,2], color = "h-A curve"), size = 2) +
  geom_line(aes(y=import[,4]/20, color = "h-V curve"), size = 2) +
  ggtitle("Stage Area Volume (hav) relationship, ANA [Tres Marias Reservoir]") +
  ylab(expression(paste("Lake Surface Area, A [",km^{2},"]"))) + xlab("Stage, h [masl]") +
  scale_colour_manual("", values = c("h-A curve"="blue", "h-V curve"="red")) +
  theme(plot.title = element_text(size = 10, face = "bold", hjust = 0.5), text=element_text(family = "Helvetica"), axis.ticks.length=unit(-0.25, "cm"), axis.text.x = element_text(margin = margin(t = 10)),
        axis.text.y = element_text(margin = margin(r = 10)), axis.text.y.right = element_text(margin = margin(l = 10)), 
        axis.title.y = element_text(margin = margin(r = 10)), axis.title.y.right = element_text(margin = margin(l = 10)),
        axis.title.x = element_text(margin = margin(t = 10)), panel.border = element_rect(colour = "black", fill=NA, size=1),
        panel.background = element_blank(), legend.position = c(0.1, 1),legend.justification = c(0, 1), 
        legend.background = element_rect(fill=alpha('white', 0))) +
  # scale_x_continuous(minor_breaks = seq(510 , 600, 10), breaks = seq(520, 600, 20), limits = c(510,600)) +
  scale_x_continuous(minor_breaks = seq(510 , 600, 10), breaks = seq(520, 600, 20), limits = c(510,600)) +
  scale_y_continuous(sec.axis = sec_axis(~.*20, name = "Lake Volume, V [mcm]"), limits = c(0,2000)) 


dev.off()




