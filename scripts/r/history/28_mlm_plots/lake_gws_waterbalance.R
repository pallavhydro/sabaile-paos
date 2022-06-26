######################################################################################################### 
##                            ---------------------------------------------------------------------------
## ========================== GW Water balance (volumes) graph from mLM output (mLM_Fluxes_States.nc)
##                            ----------------------------------------------------------------------------
## ---------- Code developer: 
## -------------------------  Pallav Kumar Shrestha pallav-kumar.shrestha@ufz.de ------
## -------------------------  08 February 2022 ----------------------------------------
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



plot_lake_gws_waterbalance <- function(path, gID, dID, title_text, subtitle_text, caption_text, ylimit ){
  
  
  # ========  CONTROL  =============================================
  
  # Parameters
  fName = "mLM_Fluxes_States.nc"
  
  # Graph control
  use_labels <- c("lake percol", "baseflow")
  use_fill <- c("orange", "grey")
  # use_linetypes <- c(2, 1, 1, 1, 1, 1, 1, 1, 1)
  
  
  # ========  READ  =============================================
  
  # Read the netCDF mLM file
  ncin <- nc_open(paste(path,fName,sep = "/"))
  # get VARIABLES  
  A         <- ncvar_get(ncin, "Larea") # only to get volumes from variables stored in mm/d
  percol    <- ncvar_get(ncin, "Lpercol")
  baseflow  <- ncvar_get(ncin, "LQbf")
  gws       <- ncvar_get(ncin, "LsatSTW")
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
  tchron <- chron(dates. = (nctime - 23)/24, origin=c(tmonth, tday, tyear)) # nctime (hours)
  tfinal <- as.POSIXct(tchron, tz = "GMT", origin=paste(tyear,tmonth,tday, sep = "-")) # nctime (hours)
  
  
  # convert to xts and VOLUMES!
  gws         <- xts(as.numeric(gws),                         order.by = tfinal)
  v_percol    <- xts(as.numeric(percol * A /1000),            order.by = tfinal)
  v_baseflow  <- xts(as.numeric(-baseflow * 86400 / 1000000), order.by = tfinal)
  
  
  # Bind
  v <- cbind(v_percol, v_baseflow)
  
  # Melt
  v_df <- data.frame(v)
  v_df$id <- rownames(v_df)
  v_melted <- melt(v_df, measure.vars=c( "v_percol", "v_baseflow"))
  gws_df <- data.frame(gws)
  gws_df$id <- rownames(gws_df)
  gws_melted <- melt(gws_df, measure.vars=c("gws"))
  # id must be date class
  v_melted$id <- rep(seq.Date(as.Date(tfinal[1]),as.Date(tail(tfinal, n = 1)), by= "days"), 2)
  gws_melted$id <- seq.Date(as.Date(tfinal[1]),as.Date(tail(tfinal, n = 1)), by= "days")
  
  
  
  
  # y limit
  if (missing(ylimit)){
    mylimit = NULL
  } else {
    mylimit = c(0, ylimit)
    vmax = ylimit
  }
  
  
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
  
  
  # Plotting the GW fluxes graph
  
  plot_lake_gw_fluxes <- ggplot() +
    
    # fluxes
    geom_area(data = v_melted, aes( x = id, y = value, fill = as.factor(variable) ), alpha = 1) +
    
    scale_fill_manual(values = use_fill,
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
      legend.text = element_text(size=14, colour = "black", hjust = c(0)),
      legend.title = element_blank(),
      legend.background = element_blank()) +
    
    scale_x_date(name = "Time", date_breaks= mydatebreaks, date_labels = "%Y", expand = c(0,0)) + # duplicating the axis for the top was not possible with date axis
    
    scale_y_continuous(name = "Flux volumes [mcm]", limits = mylimit , 
                       sec.axis = dup_axis(name ="", label = c()), expand = c(0,0))  # adding extra space at the top for annotations
  
  
  # Plotting the GW states graph
  
  plot_lake_gw_states <- ggplot() +
    
    # states
    geom_area(data = gws_melted, aes( x = id, y = value, fill = "GW storage"), alpha = 0.7) +
    
    scale_fill_manual(values = c("black"),
                      labels = c("GW storage")) +
    
    labs(title = title_text, subtitle = subtitle_text, caption = caption_text) +
    
    theme(
      text=element_text(family = "Helvetica", colour = "black"),
      axis.ticks.length=unit(-0.2, "cm"),
      axis.ticks = element_line(colour = "black", size = 0.5),
      axis.text.x = element_text(size=12, margin = margin(t = 10), colour = "black"),
      axis.title.x = element_text(size=14, margin = margin(t = 10), colour = "black"),
      axis.text.y = element_text(size=12, margin = margin(r = 10), colour = "black"),
      axis.title.y.left  = element_text(size=14, margin = margin(r = 15), colour = "black", hjust = c(0.5)),
      axis.title.y.right = element_text(size=14, margin = margin(l = 15), colour = "black", hjust = c(0.5)),
      plot.title = element_text(size = 14, colour = "black", hjust = c(0), margin = margin(b = -10), face = "bold"),
      plot.subtitle = element_text(size = 14, colour = "black", hjust = c(1)),
      plot.caption = element_text(size = 14, colour = "black", hjust = c(1)),
      panel.border = element_rect(colour = "black", fill=NA, size=1),
      panel.background = element_blank(),
      panel.grid.major = element_line(colour = alpha("black", 0.5), size=0.2, linetype = 3),
      legend.position = "top",
      legend.key = element_blank(),
      legend.key.height = unit(1, "cm"),
      legend.key.width = unit(3, "cm"),
      legend.spacing.y = unit(0.5, "cm"),
      legend.text = element_text(size=14, colour = "black", hjust = c(0)),
      legend.title = element_blank(),
      legend.background = element_blank()) +
    
    scale_x_date(name = "Time", date_breaks= mydatebreaks, date_labels = "%Y", expand = c(0,0)) + # duplicating the axis for the top was not possible with date axis
    
    scale_y_continuous(name = "State volumes [mcm]", expand = c(0,0))  # adding extra space at the top for annotations
  
  # Output
  ggsave(plot_lake_gw_fluxes, file=paste(path,"/",gID,"_lake_gw_fluxes.png",sep=""), width = 18, height = 5, units = "in")
  ggsave(plot_lake_gw_states, file=paste(path,"/",gID,"_lake_gw_states.png",sep=""), width = 18, height = 5, units = "in")
  
}

