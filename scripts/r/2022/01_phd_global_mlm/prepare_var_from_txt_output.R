## ----------------------------------------------------------------------------
## Name         prepare_var_from_txt_output (in R)
## Written      Pallav Kumar Shrestha, 2022/06/21
## Copyright    CC BY 4.0
## Purpose      Module that extracts a variable from mHM output text file format
##              and prepares an xts object.
## References
## ----------------------------------------------------------------------------



#::: LIBRARIES PREPARATION ===================


# Check for the required packages
list.of.packages <- c("chron", "xts")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages, repos = "http://cran.us.r-project.org")

# Open libraries/ packages
# silence on
oldw <- getOption("warn")
options(warn = -1) 

# Open libraries/ packages
library(chron)
library(xts) 

options(warn = oldw) 
# silence off




#::: THE FUNCTION ===================

prepare_var_from_txt_output <- function( file, var ){
  
  
  # ========  ARGUMENT DEFINITIONS  =================================
  #
  # file - path to the file including the file name and extension
  # var  - variable name that serves two purpose: 
  #           1 - as string to extract the correct column from the file
  #           2 - as column header for the xts object returned
  
  
  # ========  CONTROL  =============================================
  misVal = -9999

  
  
  # ========  READ  =============================================
    
  # Reading the TEXT  file
  
  read_in = data.frame(read.delim(file, header = T, sep = ""))  # reading the full time series
  nData <- length(read_in[,1]) # length of the time series
  data <- read_in[var] # Select the data for var
  dStart <- as.Date(paste(read_in[1,4],"-",read_in[1,3],"-",read_in[1,2],sep=""))  # Infering the start date
  dEnd <- as.Date(paste(read_in[nData,4],"-",read_in[nData,3],"-",read_in[nData,2],sep=""))  # Infering the end date
  tchron <- seq.Date(dStart,dEnd, by= "days") # date vector
  
  
  
  
  # ========  PROCESS  =============================================
  
  # Replacing missing values by NA
  data[data == misVal] <- NA
  
  # convert to xts
  data_xts <- xts(as.numeric(unlist(data)), order.by = tchron) # xts/ time series object created
  colnames(data_xts) <- var
  
  
  
  # ========  RETURN  =============================================
  
  return(data_xts)
  
}


