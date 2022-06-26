######################################################################################################### 
##                            ---------------------------------------------------------------------------
## ========================== Code to plot reservoir state and water balance components from mLM
##                            ----------------------------------------------------------------------------
## ---------- Code developer: 
## -------------------------  Pallav Kumar Shrestha pallav-kumar.shrestha@ufz.de ------
## -------------------------  29 March 2018 ----------------------------------------
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
iopath = "/Users/shresthp/tmp/eve_f2_home/home/shresthp/projects/mLM_development/02_lake_wb_simple/time_series_comparison.txt"
iopath_std = "/Users/shresthp/tmp/eve_f2_home/home/shresthp/projects/mLM_development/02_lake_wb_simple/time_series_standard.txt"
opath = "/Users/shresthp/tmp/eve_f2_home/home/shresthp/projects/mLM_development/02_lake_wb_simple/EGU18/lakeWB.jpg"

# Read the hav file
import <-read.table(iopath, skip = 2, col.names = c("day", "month", "year", "stage", "area", "lake volume", "inflow", "precipitation", "PET", "outflow_sim", "outflow_obs"))
import_std <-read.table(iopath_std, skip = 2, col.names = c("day", "month", "year", "stage", "area", "lake volume", "inflow", "precipitation", "PET", "outflow_sim", "outflow_obs"))


#---- Defining multiplot lists
plots <- list()

# Generating the date
dStart <- as.Date(paste(import[1,3],"-",import[1,2],"-",import[1,1],sep=""))  # Infering the start date
nimport <- length(import[,1])
dEnd <- as.Date(paste(import[nimport,3],"-",import[nimport,2],"-",import[nimport,1],sep=""))  # Infering the end date
date <- seq.Date(dStart,dEnd, by= "days")

# Creating the stage plot

plot1 <- ggplot(import, aes(x=date)) + geom_line(aes(y=import[,4], color="Stage, h"), size = 2) + # The color statement needs to be inside aes for the legend to appear
          ggtitle("Lake Stage, h [masl]") +
          ylab(expression(paste("Stage, h [masl]"))) + xlab("Time [days]") +
          scale_colour_manual("", values = c("Stage, h"="chartreuse3")) +
          theme(title = element_text(size = 9), text=element_text(family = "Helvetica"), axis.ticks.length=unit(-0.25, "cm"), axis.text.x = element_text(size = 9, margin = margin(t = 10)), 
                axis.text.y = element_text(size = 9, margin = margin(r = 10)), axis.title.y=element_blank(), 
                axis.title.x=element_blank(), panel.border = element_rect(colour = "black", fill=NA, size=1), 
                panel.background = element_blank(), legend.position = "none",legend.justification = c(1, 0.8), 
                legend.background = element_rect(fill=alpha('white', 0))) +
          scale_x_date(limits = as.Date(c('1984-03-01','1993-03-01')), date_breaks= "2 years", date_labels = "%Y", expand = c(0,0)) + # duplicating the axis for the top was not possible with date axis
          scale_y_continuous(limits = c(525,600), expand = c(0,0))

plot1 = ggplotGrob(plot1)
plots[[1]] <- plot1


# Creating the lake area plot

plot2 <- ggplot(import, aes(x=date)) + geom_line(aes(y=import[,5], color="Area, A"), size = 2) + # The color statement needs to be inside aes for the legend to appear
  ggtitle("Lake Area, A [sq.km.]") +
  ylab(expression(paste("Area, A [sq.km.]"))) + xlab("Time [days]") +
  scale_colour_manual("", values = c("Area, A"="chartreuse4")) +
  theme(title = element_text(size = 9), text=element_text(family = "Helvetica"), axis.ticks.length=unit(-0.25, "cm"), axis.text.x = element_text(size = 9, margin = margin(t = 10)), 
        axis.text.y = element_text(size = 9, margin = margin(r = 10)), axis.title.y=element_blank(), 
        axis.title.x=element_blank(), panel.border = element_rect(colour = "black", fill=NA, size=1), 
        panel.background = element_blank(), legend.position = "none",legend.justification = c(1, 0.8), 
        legend.background = element_rect(fill=alpha('white', 0))) +
  scale_x_date(limits = as.Date(c('1984-03-01','1993-03-01')), date_breaks= "2 years", date_labels = "%Y", expand = c(0,0))   # duplicating the axis for the top was not possible with date axis
  # scale_y_continuous(limits = c(0,2000), expand = c(0,0))

plot2 = ggplotGrob(plot2)
plots[2] <- plot2



# Creating the lake volume plot

plot3 <- ggplot(import, aes(x=date)) + geom_line(aes(y=import[,6], color="Volume, V"), size = 2) + # The color statement needs to be inside aes for the legend to appear
  ggtitle("Lake Volume, V [mcm]") +
  ylab(expression(paste("Volume, V [mcm]"))) + xlab("Time [days]") +
  scale_colour_manual("", values = c("Volume, V"="seagreen3")) +
  theme(title = element_text(size = 9), text=element_text(family = "Helvetica"), axis.ticks.length=unit(-0.25, "cm"), axis.text.x = element_text(size = 9, margin = margin(t = 10)), 
        axis.text.y = element_text(size = 9, margin = margin(r = 10)), axis.title.y=element_blank(), 
        axis.title.x=element_blank(), panel.border = element_rect(colour = "black", fill=NA, size=1), 
        panel.background = element_blank(), legend.position = "none",legend.justification = c(1, 0.8), 
        legend.background = element_rect(fill=alpha('white', 0))) +
  scale_x_date(limits = as.Date(c('1984-03-01','1993-03-01')), date_breaks= "2 years", date_labels = "%Y", expand = c(0,0))    # duplicating the axis for the top was not possible with date axis
  # scale_y_continuous(limits = c(0,1000), expand = c(0,0))

plot3 = ggplotGrob(plot3)
plots[[3]] <- plot3


# Creating the lake precipitation plot

plot4 <- ggplot(import_std, aes(x=date)) + geom_col(aes(y=import_std[,8], color="Precipitation"), size = 1) + # The color statement needs to be inside aes for the legend to appear
  ggtitle("Lake Precipitation [mm.day-1]") +
  ylab(expression(paste("Precipitation [mm.day-1]"))) + xlab("Time [days]") +
  scale_colour_manual("", values = c("Precipitation"="blue")) +
  theme(title = element_text(size = 9), text=element_text(family = "Helvetica"), axis.ticks.length=unit(-0.25, "cm"), axis.text.x = element_text(size = 9, margin = margin(t = 10)), 
        axis.text.y = element_text(size = 9, margin = margin(r = 10)), axis.title.y=element_blank(), 
        axis.title.x=element_blank(), panel.border = element_rect(colour = "black", fill=NA, size=1), 
        panel.background = element_blank(), legend.position = "none",legend.justification = c(1, 0.8), 
        legend.background = element_rect(fill=alpha('white', 0))) +
  scale_x_date(limits = as.Date(c('1984-03-01','1993-03-01')), date_breaks= "2 years", date_labels = "%Y", expand = c(0,0)) +   # duplicating the axis for the top was not possible with date axis
  scale_y_reverse(limits = c(100,0), expand = c(0,0))

plot4 = ggplotGrob(plot4)
plots[[4]] <- plot4


# Creating the lake PET plot

plot5 <- ggplot(import_std, aes(x=date)) + geom_line(aes(y=import_std[,9], color="PET"), size = 0.5) + # The color statement needs to be inside aes for the legend to appear
  ggtitle("Lake PET [mm.day-1]") +
  ylab(expression(paste("PET [mm.day-1]"))) + xlab("Time [days]") +
  scale_colour_manual("", values = c("PET"="gray41")) +
  theme(title = element_text(size = 9), text=element_text(family = "Helvetica"), axis.ticks.length=unit(-0.25, "cm"), axis.text.x = element_text(size = 9, margin = margin(t = 10)), 
        axis.text.y = element_text(size = 9, margin = margin(r = 10)), axis.title.y=element_blank(), 
        axis.title.x=element_blank(), panel.border = element_rect(colour = "black", fill=NA, size=1), 
        panel.background = element_blank(), legend.position = "none",legend.justification = c(1, 0.8), 
        legend.background = element_rect(fill=alpha('white', 0))) +
  scale_x_date(limits = as.Date(c('1984-03-01','1993-03-01')), date_breaks= "2 years", date_labels = "%Y", expand = c(0,0)) +   # duplicating the axis for the top was not possible with date axis
  scale_y_continuous(limits = c(0,10), expand = c(0,0))

plot5 = ggplotGrob(plot5)
plots[[5]] <- plot5


# Creating the lake water balance component analysis plot

plot6 <- ggplot(import, aes(x=date)) + geom_line(aes(y=import[,7], color="Inflow"), size = 0.5) + # The color statement needs to be inside aes for the legend to appear
  geom_line(aes(y=import[,8], color="Lake precipitation"), size = 0.5) +
  geom_line(aes(y=import[,9], color="Lake ET"), size = 0.5) +
  geom_line(aes(y=import[,11], color="Outflow"), size = 0.5) +
  ggtitle("Lake Water Balance [mcm]") +
  ylab(expression(paste("Contribution [mcm]"))) + xlab("Time [days]") +
  scale_colour_manual("", values = c("Inflow"="red","Lake precipitation"="blue","Lake ET"="black","Outflow"="dodgerblue3")) +
  theme(title = element_text(size = 9), text=element_text(family = "Helvetica"), axis.ticks.length=unit(-0.25, "cm"), axis.text.x = element_text(size = 9,margin = margin(t = 10)), 
        axis.text.y = element_text(size = 9, margin = margin(r = 10)), axis.title.y=element_blank(), 
        axis.title.x=element_blank(), panel.border = element_rect(colour = "black", fill=NA, size=1), 
        panel.background = element_blank(), legend.position = c(1, 0.9),legend.justification = c(1, -0.2), 
        legend.background = element_rect(fill=alpha('white', 0)), legend.direction = "horizontal", legend.text = element_text(size = 9)) +
  scale_x_date(limits = as.Date(c('1984-03-01','1993-03-01')), date_breaks= "2 years", date_labels = "%Y", expand = c(0,0))  +  # duplicating the axis for the top was not possible with date axis
  scale_y_continuous(limit = c(0, 500), expand = c(0,0))

plot6 = ggplotGrob(plot6)
plots[[6]] <- plot6


# ---- Describing the layout
xlay <- matrix(c(1,2,3,4,6,6), 3, 2, byrow = FALSE) 

select_grobs <- function(lay) {
  id <- unique(c(t(lay)))
  id[!is.na(id)]
}


# jpeg(opath, width=12, height=4, units = "in", res = 300)
# grid.arrange(plot1, plot2, plot3, plot4, plot6, plot6, layout_matrix=xlay)
grid.arrange(plot1, plot2, plot3, plot4, plot6,
             layout_matrix= rbind(c(1,2,3),
                                  c(4,6,6))
             )
# dev.off()
