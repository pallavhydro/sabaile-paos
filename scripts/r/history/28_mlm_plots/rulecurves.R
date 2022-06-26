######################################################################################################### 
##                            ---------------------------------------------------------------------------
## ========================== Rule Curves and Water level from mHM output
##                            ----------------------------------------------------------------------------
## ---------- Code developer: 
## -------------------------  Pallav Kumar Shrestha pallav-kumar.shrestha@ufz.de ------
## -------------------------  18 November 2021 ----------------------------------------
#########################################################################################################



# Open libraries/ packages
library(ggplot2)
library(ncdf4) 
library(chron)
library(xts) 
library(reshape) # for melt
library(stringr) # for str_pad



plot_rulecurve <- function(path, damID, title_text, subtitle_text, caption_text ){


  # ========  CONTROL  =============================================
  
  # path = "."
  # damname = "Selingue"
  # domainid = 1134040
  # damID = 3013
  # title_text <- paste(paste("dam: ", damname), paste("gauge: ", domainid), sep = " . ")
  # subtitle_text <- paste(paste("dam V: ", "mcm", sep = " "), paste("c.a. ", "sq.kms. ", sep = " "), 
  #                        paste("c.a. ratio "), sep = " . ")
  # text <- paste("non-dam: ", sep = "")
  # caption_text <- paste("dam: calibration", text, sep = " . ")
  
  # Parameters
  fName_rc = paste("daily_regulation_lake", damID, ".bal", sep = "")
  fName_wl = "lakeLevel.nc"
  fName_eva= paste(damID, "_check_EVA_and_DCL.out", sep = "")
  misVal = -9999.0
  ToICol = 13
  ToCCol = 14
  ToFCCol = 15
  
  # Graph control
  use_labels <- c("ToFC", "ToC", "ToI", "WL observed", "WL mHM")
  use_colors <- c("red", "orange", "black", "red", "blue")
  use_linetypes <- c(1, 1, 1, 2, 1)
  
  
  # ========  READ  =============================================
  
  # Reading the operational curves (tab delimited file)
  data_rc = data.frame(read.delim(paste(path,"/../",fName_rc,sep=""), header = TRUE, sep = "", skip = 3))  # reading all the data
  data_rc[data_rc == misVal] <- NA
  dStart <- as.Date(paste(data_rc[1,4],"-",data_rc[1,3],"-",data_rc[1,2],sep=""))  # Infering the start date
  ndata_rc <- length(data_rc[,1])
  dEnd <- as.Date(paste(data_rc[ndata_rc,4],"-",data_rc[ndata_rc,3],"-",data_rc[ndata_rc,2],sep=""))  # Infering the end date
  date <- seq.Date(dStart,dEnd, by= "days")
  
  
  # Read the netCDF lake level file
  ncin <- nc_open(paste(path,fName_wl,sep = "/"))
  # get VARIABLES
  wl_obs <- ncvar_get(ncin, paste("Lobs_", str_pad(damID, 10, pad = "0"), sep = ""))
  wl_sim <- ncvar_get(ncin, paste("Lsim_", str_pad(damID, 10, pad = "0"), sep = ""))
  wl_obs[wl_obs == misVal] <- NA
  wl_sim[wl_sim == misVal] <- NA
  # Read time attribute
  nctime <- ncvar_get(ncin,"time")
  tunits <- ncatt_get(ncin,"time","units")
  nt <- dim(nctime)
  # Close file
  nc_close(ncin)
  
  # Reading the DCL and Bed level elevations (tab delimited file)
  data_eva = data.frame(read.delim(paste(path,"/../",fName_eva,sep=""), header = FALSE, sep = "", skip = 4))  # reading all the data
  ndata_eva <- length(data_eva[,1])
  elev_bed <- data_eva[1,1]
  elev_dcl <- data_eva[ndata_eva, 1]
  
  
  
  
  # ========  PROCESS  =============================================
  
  # Prepare the time origin
  tustr <- unlist(strsplit(tunits$value, " "))
  tdstr <- unlist(strsplit((rev(tustr))[2], "-"))
  tmonth <- as.integer(tdstr)[2]
  tday <- as.integer(tdstr)[3]
  tyear <- as.integer(tdstr)[1]
  tchron <- chron(dates. = (nctime - 23)/24, origin=c(tmonth, tday, tyear)) # nctime (hours)
  tfinal <- as.POSIXct(tchron, tz = "GMT", origin=paste(tyear,tmonth,tday, sep = "-")) # nctime (hours)
  
  # convert to xts
  rc_tofc<- xts(as.numeric(data_rc[1:length(tfinal),ToFCCol]), order.by = tfinal)
  rc_toc <- xts(as.numeric(data_rc[1:length(tfinal),ToCCol]),  order.by = tfinal)
  rc_toi <- xts(as.numeric(data_rc[1:length(tfinal),ToICol]),  order.by = tfinal)
  
  wl_obs <- xts(as.numeric(wl_obs), order.by = tfinal) # xts/ time series object created
  wl_sim <- xts(as.numeric(wl_sim), order.by = tfinal)
  
  
  # Bind
  data <- cbind(rc_tofc, rc_toc, rc_toi, wl_obs, wl_sim)
  # Melt
  data_df <- data.frame(data)
  data_df$id <- rownames(data_df)
  data_melted <- melt(data_df, measure.vars=c("rc_tofc", "rc_toc", "rc_toi", "wl_obs", "wl_sim"))
  # id must be date class
  data_melted$id <- rep(seq.Date(as.Date(tfinal[1]),as.Date(tail(tfinal, n = 1)), by= "days"), 5)
  
  
  mylimit <- c(0.99*elev_bed, 1.01*elev_dcl)
  
  # adjust pdf width for long hydrographs
  nyrs = as.numeric(format(tail(tfinal, n = 1),'%Y')) - as.numeric(format(tfinal[1],'%Y')) + 1
  if (nyrs > 10){
    mydatebreaks = "5 years"
    pdf_width = 12 + (nyrs - 10)
  } else {
    mydatebreaks = "1 year"
    pdf_width = 12
  }
  
  
  # ========  PLOT  =============================================
  
  date_range = paste(as.numeric(format(tfinal[1],'%Y')), as.numeric(format(tail(tfinal, n = 1),'%Y')), sep = "-")
  caption_text <- paste(caption_text, date_range, sep = " . ")
  
  # Plotting the hydrograph
  
  main <- ggplot() +
    # Rule curves and water levels
    geom_line(data = data_melted, aes( x = id, y = value, color = as.factor(variable), linetype = as.factor(variable) ), size = 1, alpha = 1) +
    # DCL and Bed
    geom_hline(yintercept = elev_dcl, color = "black", alpha = 0.3, size = 3, linetype = 1) +
    geom_hline(yintercept = elev_bed, color = "black", alpha = 0.3, size = 3, linetype = 1) +
    
    scale_color_manual(values = use_colors,
                       labels = use_labels) +
    
    scale_linetype_manual(values = use_linetypes,
                          labels = use_labels) +
    
    labs(title = title_text, subtitle = subtitle_text, caption = caption_text) +
    
    theme(
      text=element_text(family = "Helvetica", colour = "black"),
      axis.ticks.length=unit(-0.2, "cm"),
      axis.ticks = element_line(colour = "black", size = 0.5),
      axis.text.x = element_text(size=12, margin = margin(t = 10), colour = "black"),
      axis.title.x = element_text(size=14, margin = margin(t = 10), colour = "black"),
      axis.text.y = element_text(size=12, margin = margin(r = 10), colour = "black"),
      axis.title.y.left  = element_text(size=14, margin = margin(r = 15), colour = "black", hjust = c(0.5)),
      axis.title.y.right = element_blank(),
      plot.title = element_text(size = 14, colour = "black", hjust = c(0), margin = margin(b = -10), face = "bold"),
      plot.subtitle = element_text(size = 14, colour = "black", hjust = c(1)),
      plot.caption = element_text(size = 14, colour = "black", hjust = c(1)),
      panel.border = element_rect(colour = "black", fill=NA, size=1),
      panel.background = element_blank(),
      panel.grid.major = element_line(colour = alpha("black", 0.5), size=0.2, linetype = 3),
      legend.position = "top", # c(0.6, 0.9),
      legend.direction = "horizontal",
      legend.key = element_blank(),
      legend.key.height = unit(1, "cm"),
      legend.key.width = unit(1.5, "cm"),
      legend.spacing.y = unit(0.5, "cm"),
      legend.text = element_text(size=14, colour = "black", hjust = c(0)),
      legend.title = element_blank(),
      legend.background = element_rect(fill=alpha("white", 0.8))) +
    
    scale_x_date(name = "Time", date_breaks= mydatebreaks, date_labels = "%Y", expand = c(0,0)) + # duplicating the axis for the top was not possible with date axis
  
    scale_y_continuous(name = "Elevation [m a.s.l.]", limits = mylimit , sec.axis = dup_axis(name ="", labels = c()), expand = c(0,0))  # adding extra space at the top for annotations
  
  # Output
  ggsave(main, file=paste(path,"/",damID,"_rulecurve.pdf",sep=""), width = 18, height = 5, units = "in")

}


