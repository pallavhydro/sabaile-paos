###################################################################################################
##                   -------------------------------------------
## ==================   Formatting edk input    ===================================
##                   -------------------------------------------
##   
##  Author:    Pallav Kumar Shrestha    (pallav-kumar.shrestha@ufz.de)
##             25 Oct 2021
##
##  Usage:     Place this file alongside excel file/s 
##
###################################################################################################  

library(stringr)
 
setwd("/Users/shresthp/Nextcloud/Cloud/macbook/01_work/Collab/03_edk_Nepal_PraladPhuyal_IOE/pp/20211025/")

# Store the data from the CSV file
data <- read.csv("Rainfall.csv", header = TRUE)


station_name <- "dummybesi"
latitude <- 27.987
longitude <- 83.122 
altitude <- 201

syear <- 1987
smonth <- 1
sday <- 1
eyear <- 2010
emonth <- 12
eday <- 31

# Check whether the file exists and if so, delete the existing file
if(file.exists("test.txt")){
  file.remove("test.txt")
}


# Format the first two lines
line_1 <- sprintf("Station: %s , scaling_factor: 1, latitude:  %f, longitude:  %f, altitude:  %f, nodata_value: -99.00\n", 
                  station_name, latitude, longitude, altitude)
line_2 <- sprintf("start: ..%i-%s-%s  end: ..%i-%s-%s\n", 
                  syear, str_pad(smonth, 2, pad = "0"), str_pad(sday, 2, pad = "0"), 
                  eyear, str_pad(emonth, 2, pad = "0"), str_pad(eday, 2, pad = "0"))

# Reference -
# Station: Aken/Elbe , scaling_factor: 10.0, latitude:  51.8506, longitude:  12.0491, altitude:  55, nodata_value: -9
# start: ..1969-01-01  end: ..2015-12-31

# Add these lines to the file
cat(line_1, file = "test.txt", append = FALSE)
cat(line_2, file = "test.txt", append = TRUE)

# dump the data of this station to the file
write.table(as.numeric(data[,2]), append = TRUE, file="test.txt", row.names=FALSE, col.names = FALSE)

