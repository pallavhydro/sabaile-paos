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

# Title of plot
graphTitle = "OF Evolution. KGE . DDS . dWL"

# Set the IO directory
iopath = "/Users/shresthp/tmp/eve_data_sawam/sawam/data/processed/mlmdevelopment/mlm_test_area/tests/i150_OFdeltas/03_output/OR_isolated/40_dwl_kge/"

# Reading the optimization file
data = data.frame(read.delim(paste(iopath,fName,sep=""), skip = 7, header=FALSE, sep = ""))  # reading all the data
data <- data[,1:2] # Storing only iteration count and OF
nIte <- length(data[,1])    # count number of iterations on the file


cParam = c("chartreuse3", "cornsilk4", "gold3", "royalblue4", 
           "coral", "lightseagreen", "royalblue1", "steelblue1", "brown4", "royalblue4", "coral", "lightseagreen")
#-----------------------------------------
# Plotting the OF evoluation plot

jpeg(paste(iopath,fName,".jpg",sep=""), width=4, height=3, units = "in", res = 300)


# main <- ggplot(data, aes(x=date)) + geom_line(aes(y=data[,ToFCCol], color="ToFC")) + # The color statement needs to be inside aes for the legend to appear
#   geom_line(aes(y=data[,ToCCol], color="ToC")) + geom_line(aes(y=data[,ToICol], color="ToI")) +
#   ggtitle("Rule Curves : Tres Marias") + geom_line(aes(y=data_wl[,simCol], color="WL sim")) + geom_line(aes(y=data_wl[,obsCol], color="WL obs")) +
#   ylab(expression(paste("Elevation [masl]"))) + xlab("Year") +
#   scale_colour_manual("", values = c("ToFC"="blue", "ToC"="green", "ToI"="orange", "WL obs"="black", "WL sim" = "red")) +
#   theme(text=element_text(family = "Helvetica"), axis.ticks.length=unit(-0.25, "cm"), axis.text.x = element_text(size=10, margin = margin(t = 10)),
#         axis.text.y = element_text(size=10, margin = margin(r = 10)), axis.title.y = element_text(size=10, margin = margin(r = 10)),
#         axis.title.x = element_text(size=10, margin = margin(t = 20)), panel.border = element_rect(colour = "black", fill=NA, size=1),
#         panel.background = element_blank(), legend.position = "top", legend.justification = c(1, 0.8),
#         legend.background = element_rect(fill=alpha('white', 0)), plot.title = element_text(size = 15, face = "bold"), legend.text = element_text(size=15)) +
#   scale_x_date(date_breaks= "1 year", date_labels = "%Y", expand = c(0,0)) + # duplicating the axis for the top was not possible with date axis
#   scale_y_continuous(sec.axis = dup_axis(name ="", labels = c()), limits = c(minval*0.99, maxval*1.01), expand = c(0,0))  # adding extra space at the top for annotations


xplot <- ggplot(data, aes(x=data[,1])) + geom_line(aes(y=data[,2]), color = "chartreuse3") +
  ggtitle(graphTitle) +
  ylab(expression(paste("Objective Function"))) + xlab("Iteration count") +
  theme(legend.position = "none",
        title = element_text(family = "Helvetica", size = 10), axis.ticks.length=unit(-0.25, "cm"), axis.text.x = element_text(size=10, margin = margin(t = 10)),
        axis.text.y = element_text(size=10, margin = margin(r = 10)), axis.title.y = element_text(size=10, margin = margin(r = 10)),
        axis.title.x = element_text(size=10, margin = margin(t = 20)), panel.border = element_rect(colour = "black", fill=NA, size=1),
        panel.background = element_blank()) +
  scale_y_continuous(sec.axis = dup_axis(name ="", labels = c()), expand = c(0,0)) +
  expand_limits(y=0)

xplot

dev.off()


