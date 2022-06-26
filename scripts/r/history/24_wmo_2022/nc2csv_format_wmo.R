######################################################################################################### 
##                            ---------------------------------------------------------------------------
## ========================== netcdf to csv format (WMO 2022)
##                            ----------------------------------------------------------------------------
## ---------- Code developer: 
## -------------------------  Pallav Kumar Shrestha pallav-kumar.shrestha@ufz.de ------
## -------------------------  26 April 2022 ----------------------------------------
#########################################################################################################

#### Gives one set of skill scores for the whole simulation period


# Open libraries/ packages
library(ncdf4) 
library(chron)
library(xts) 




  
  # ========  CONTROL  =============================================
  
  # Command line arguments (1 - path, 2 - file name without extension)
  args <- commandArgs(trailingOnly = TRUE)

  # Parameters
  path = args[1]
  fName = args[2]
  
  # WMO nodata
  nodata_wmo = -999.000
  
  # Time window
  syear <- 1991
  eyear <- 2021
  
  
  # ========  READ  =============================================
  
  # Read the netCDF mLM file
  ncin <- nc_open(paste(path,paste(fName,".nc", sep = ""), sep = "/"))
  # get VARIABLE
  q      <- ncvar_get(ncin, "qsim")
  # Read time attribute
  nctime <- ncvar_get(ncin,"time")
  tunits <- ncatt_get(ncin,"time","units")
  nt <- dim(nctime)
  # Close file
  nc_close(ncin)
  
  
  
  # ========  PROCESS  =============================================

  # Prepare the time origin
  tustr <- unlist(strsplit(tunits$value, " "))
  tdstr <- unlist(strsplit(tustr[3], "-"))
  tmonth <- as.integer(tdstr)[2]
  tday <- as.integer(tdstr)[3]
  tyear <- as.integer(tdstr)[1]
  tchron <- chron(dates. = nctime, origin=c(tmonth, tday, tyear)) # nctime (hours)
  tfinal <- as.POSIXct(tchron, tz = "GMT", origin=paste(tyear,tmonth,tday, sep = "-")) # nctime (hours)
  
  # convert variable to XTS and round up
  q_to_fill  <- xts(as.numeric(round(q, 3)),  order.by = tfinal)
  
  # prepare XTS with continuous data index
  sdate <- tfinal[1]
  edate <- tfinal[length(tfinal)]
  dates <- seq(sdate, edate, by="days")
  q <- xts(order.by = dates)
  
  # Fill data
  q <- cbind(q, q_to_fill)
  q[is.na(q)] <- nodata_wmo
  
  # Time window subset
  q <- q[paste(syear, eyear, sep = "/")]
  
  # remove time from index of XTS
  tclass(q) <- "Date"
  # Give colnames
  colnames(q) <- "Discharge" 
  
  
  
  # ========  SAVE TO CSV =============================================

  fName_wmo <- paste(unlist(strsplit(fName, "_"))[2], "_wmo-basin-", unlist(strsplit(fName, "_"))[1], ".csv", sep = "")
  write.zoo(q, file=paste(path,fName_wmo, sep = "/"), sep=",", index.name = "Date", col.names = TRUE, quote = FALSE)

  
