######################################################################################################### 
##                            ---------------------------------------------------------------------------
## ========================== Power Spectrum Analysis (from water level and discharge data input files for mHM)
##                            ----------------------------------------------------------------------------
## ---------- Code developer: 
## -------------------------  Pallav Kumar Shrestha pallav-kumar.shrestha@ufz.de ------
## -------------------------  25 November 2020 ----------------------------------------
#########################################################################################################

library(stats)
library(ggplot2)
library(cowplot)
library(ggplotify)
library(gridExtra)  # for using "grid.arrange" function


# Defining MULTIPLOT lists
plots <- list()
nColPlot <- 1
nRowPlot <- 3


# Function to plot a frequency spectrum
plot.frequency.spectrum <- function(X.k, xlimits=c(0,length(X.k))) {
  plot.data  <- cbind(0:(length(X.k)-1), Mod(X.k))
  
  # TODO: why this scaling is necessary?
  plot.data[2:length(X.k),2] <- 2*plot.data[2:length(X.k),2] 
  
  plot(plot.data, t="h", lwd=2, main="", 
       xlab="Frequency (Hz)", ylab="Strength", 
       xlim=xlimits, ylim=c(0,max(Mod(plot.data[,2]))))
}




# Set working directory and file name
setwd("/Users/shresthp/Nextcloud/Cloud/macbook/01_work/R/scripts/20_fftanalysis/hydropower use/2516/")
filename = "2516.hyd"


#==== Data ====
# Read the time seties data file
data <- read.delim(filename, header = FALSE, sep = "", skip = 5)
data[data == -9999] <- NA # Replace missing values with NA
data <- data[,6]

# Time series plot
jpeg("timeseries.jpg", width = 5, height = 4, units = "in", res = 300)
plot(data, type = "l", xlab = "time (days)", ylab = "elevation (masl)")
dev.off()


#==== ACF ====
# Get the Autocorrelation function for the time series data
jpeg("acf.jpg", width = 5, height = 4, units = "in", res = 300)
acf_data <- acf(data, lag.max = 365, na.action = na.pass, main = NULL )
dev.off()


#==== FFT ====
# FFT on the ACF of the time series
fft_data <- fft(Mod(acf_data$acf))

# Plot the frequency strength from ACF's FFT
jpeg("fft_on_acf.jpg", width = 5, height = 4, units = "in", res = 300)
plot.frequency.spectrum(fft_data, xlimits=c(0,50))
dev.off()


