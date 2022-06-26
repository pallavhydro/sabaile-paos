######################################################################################################### 
##                            ---------------------------------------------------------------------------
## ========================== Hydrographs Generation from mLM output (mLM_Fluxes_States.nc)
##                            ----------------------------------------------------------------------------
## ---------- Code developer: 
## -------------------------  Pallav Kumar Shrestha pallav-kumar.shrestha@ufz.de ------
## -------------------------  07 February 2022 ----------------------------------------
#########################################################################################################

#### Gives one set of skill scores for the whole simulation period


# Open libraries/ packages
library(ggplot2)
library(ncdf4) 
library(chron)
library(xts) 
library(reshape) # for melt
library(stringr) # for str_pad
library(ragg)    # for scaling plot



plot_lake_hydrographs <- function(path, gID, title_text, subtitle_text, caption_text, ylimit ){


  # ========  CONTROL  =============================================
  
  # Parameters
  fName = "mLM_Fluxes_States.nc"
  fName_qobs = "discharge.nc"
  misVal = -9999.0
  
  # Graph control
  use_labels <- c("observed", "inflow", "outflow", "baseflow", "spill", "use_hydro", "use_irrig", "use_wsupply", "use_environ")
  use_colors <- c("grey", "black", "blue", "green", "red", "grey", "grey", "grey", "grey")
  use_linetypes <- c(1, 2, 1, 1, 2, 1, 1, 1, 1)
  
  
  # ========  READ  =============================================
  
  # Read the netCDF mLM file
  ncin <- nc_open(paste(path,fName,sep = "/"))
  # get VARIABLES
  q_inflow    <- ncvar_get(ncin, "LQin")
  q_outflow   <- ncvar_get(ncin, "LQout")
  q_baseflow  <- ncvar_get(ncin, "LQbf")
  q_spill     <- ncvar_get(ncin, "LQspl")
  q_hydro     <- ncvar_get(ncin, "LQhyp")
  q_irrig     <- ncvar_get(ncin, "LQirr")
  q_wsupply   <- ncvar_get(ncin, "LQwsp")
  q_env       <- ncvar_get(ncin, "LQenv")
  # Read time attribute
  nctime <- ncvar_get(ncin,"time")
  tunits <- ncatt_get(ncin,"time","units")
  nt <- dim(nctime)
  # Close file
  nc_close(ncin)
  
  # Read the netCDF discharge file
  ncin <- nc_open(paste(path,fName_qobs,sep = "/"))
  # get VARIABLES
  q_obs <- ncvar_get(ncin, paste("Qobs_", str_pad(gID, 10, pad = "0"), sep = ""))
  q_obs[q_obs == misVal] <- NA
  # Close file
  nc_close(ncin)
  
  
  
  
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
  q_obs       <- xts(as.numeric(q_obs),     order.by = tfinal) # xts/ time series object created
  q_inflow    <- xts(as.numeric(q_inflow),  order.by = tfinal)
  q_outflow   <- xts(as.numeric(q_outflow), order.by = tfinal)
  q_baseflow  <- xts(as.numeric(q_baseflow),order.by = tfinal)
  q_spill     <- xts(as.numeric(q_spill),   order.by = tfinal)
  q_hydro     <- xts(as.numeric(q_hydro),   order.by = tfinal)
  q_irrig     <- xts(as.numeric(q_irrig),   order.by = tfinal)
  q_wsupply   <- xts(as.numeric(q_wsupply), order.by = tfinal)
  q_env       <- xts(as.numeric(q_env),     order.by = tfinal)
  
  
  # Bind
  q <- cbind(q_obs, q_inflow, q_outflow, q_baseflow, q_spill, q_hydro, q_irrig, q_wsupply, q_env)
  # Melt
  q_df <- data.frame(q)
  q_df$id <- rownames(q_df)
  q_melted <- melt(q_df, measure.vars=c("q_obs", "q_inflow", "q_outflow", "q_baseflow", "q_spill", "q_hydro", "q_irrig", "q_wsupply", "q_env"))
  # id must be date class
  q_melted$id <- rep(seq.Date(as.Date(tfinal[1]),as.Date(tail(tfinal, n = 1)), by= "days"), length(use_labels))
  
  
  qmax <- max(q, na.rm = TRUE)
  
  # y limit
  if (missing(ylimit)){
    mylimit = NULL
  } else {
    mylimit = c(0, ylimit)
    qmax = ylimit
  }
  
  translucentPosY1 <- qmax*0.55
  translucentPosY2 <- qmax*0.95
  translucentPosX1 <- as.Date(tfinal[1])
  translucentPosX2 <- as.Date(tail(tfinal, n = 1))
  
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
  
  # date_range = paste(as.numeric(format(tfinal[1],'%Y')), as.numeric(format(tail(tfinal, n = 1),'%Y')), sep = "-")
  # caption_text <- paste(caption_text, date_range, sep = " . ")
  
  # Plotting the hydrograph
  
  main <- ggplot() +
    # hydrographs
    geom_line(data = q_melted, aes( x = id, y = value, color = as.factor(variable), linetype = as.factor(variable) ), size = 1, alpha = 1) +
    
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
      legend.position = "top",
      legend.key = element_blank(),
      legend.key.height = unit(1, "cm"),
      legend.key.width = unit(1.5, "cm"),
      legend.spacing.y = unit(0.5, "cm"),
      # legend.direction = "horizonal",
      legend.text = element_text(size=14, colour = "black", hjust = c(0)),
      legend.title = element_blank(),
      legend.background = element_blank()) +
    
    scale_x_date(name = "Time", date_breaks= mydatebreaks, date_labels = "%Y", expand = c(0,0)) + # duplicating the axis for the top was not possible with date axis
  
    scale_y_continuous(name = expression(paste("Flow [",m^{3},".",s^{-1},"]")), limits = mylimit , sec.axis = dup_axis(name ="", labels = c()), expand = c(0,0))  # adding extra space at the top for annotations
  
  # Output
  ggsave(main, file=paste(path,"/",gID,"_lake_hydrographs.png",sep=""), width = 18, height = 5, units = "in")

}
