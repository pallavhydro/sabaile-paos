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
library(stringr) # for str_pad




  
  # ========  CONTROL  =============================================
  
  # Command line arguments (1 - path, 2 - file name without extension)
  args <- commandArgs(trailingOnly = TRUE)

  # Parameters
  ipath = args[1]
  opath = args[2]
  sName = args[3]
  
  # WMO nodata
  nodata_wmo = -999.000
  
  # Time window
  syear <- 1991
  eyear <- 2021
  
  
  # ========  READ  =============================================
  
  # Read the netCDF mLM file
  ncin <- nc_open(paste(ipath, "discharge.nc", sep = "/"))
  # get VARIABLE
  q      <- ncvar_get(ncin, paste("Qsim_", str_pad(sName, 10, pad = "0"), sep = "")) 
  # Read time attribute
  nctime <- ncvar_get(ncin,"time")
  tunits <- ncatt_get(ncin,"time","units")
  nt <- dim(nctime)
  # Close file
  nc_close(ncin)
  
  
  
  # ========  PROCESS  =============================================

  # Prepare the time origin
  
  tustr <- unlist(strsplit(tunits$value, " "))
  tdstr <- unlist(strsplit((rev(tustr))[2], "-"))
  tmonth <- as.integer(tdstr)[2]
  tday <- as.integer(tdstr)[3]
  tyear <- as.integer(tdstr)[1]
  tchron <- chron(dates. = nctime/24, origin=c(tmonth, tday, tyear)) # nctime (hours)
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

  fName_wmo <- paste("mhm_wmo-basin-", sName, ".csv", sep = "")
  write.zoo(q, file=paste(opath,fName_wmo, sep = "/"), sep=",", index.name = "Date", col.names = TRUE, quote = FALSE)

  
