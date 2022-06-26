######################################################################################################### 
##                            ---------------------------------------------------------------------------
## ========================== Water balance (volumes) graph from mLM output (mLM_Fluxes_States.nc)
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



plot_lake_waterbalance <- function(path, gID, dID, title_text, subtitle_text, caption_text, ylimit ){
  
  
  # ========  CONTROL  =============================================
  
  # Parameters
  fName = "mLM_Fluxes_States.nc"
  fName_DCL = paste(dID, "_check_EVA_and_DCL.out", sep = "")
  
  # Graph control
  use_labels <- c("inflow", "lake pre", "spill", "lake percol", "lake evap", "use_hydro", "use_irrig", "use_wsupply", "use_environ")
  use_fill <- c("grey", "black", "dodgerblue", "orange", "red", "grey", "grey", "grey", "grey")
  # use_linetypes <- c(2, 1, 1, 1, 1, 1, 1, 1, 1)
  
  
  # ========  READ  =============================================
  
  # Read the netCDF mLM file
  ncin <- nc_open(paste(path,fName,sep = "/"))
  # get VARIABLES
  A         <- ncvar_get(ncin, "Larea") # only to get volumes from variables stored in mm/d
  h         <- ncvar_get(ncin, "Llevel")
  V         <- ncvar_get(ncin, "Lvolume")
  inflow    <- ncvar_get(ncin, "LQin")
  pre       <- ncvar_get(ncin, "Lpre")
  spill     <- ncvar_get(ncin, "LQspl")
  percol    <- ncvar_get(ncin, "Lpercol")
  evap      <- ncvar_get(ncin, "Levap")
  hydro     <- ncvar_get(ncin, "LQhyp")
  irrig     <- ncvar_get(ncin, "LQirr")
  wsupply   <- ncvar_get(ncin, "LQwsp")
  env       <- ncvar_get(ncin, "LQenv")
  # Read time attribute
  nctime <- ncvar_get(ncin,"time")
  tunits <- ncatt_get(ncin,"time","units")
  nt <- dim(nctime)
  # Close file
  nc_close(ncin)
  
  # Read the DCL check file
  dcl_data  <- read.delim(fName_DCL, sep = ":", nrows = 4, header = FALSE)
  dcl       <- as.numeric(dcl_data[1, 2])
  dcl_vol   <- as.numeric(dcl_data[4, 2])
  
  
  
  
  
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
  V           <- xts(as.numeric(V),                          order.by = tfinal)
  h           <- xts(as.numeric(h),                          order.by = tfinal)
  v_inflow    <- xts(as.numeric(inflow * 86400 / 1000000),   order.by = tfinal) # converting to mcm 
  v_pre       <- xts(as.numeric(pre * A / 1000) ,            order.by = tfinal) # converting to mcm (mm/d * sq.kms)
  v_spill     <- xts(as.numeric(-spill * 86400 / 1000000),   order.by = tfinal)
  v_percol    <- xts(as.numeric(-percol * A /1000),          order.by = tfinal)
  v_evap      <- xts(as.numeric(-evap * A / 1000),           order.by = tfinal)
  v_hydro     <- xts(as.numeric(-hydro * 86400 / 1000000),   order.by = tfinal)
  v_irrig     <- xts(as.numeric(-irrig * 86400 / 1000000),   order.by = tfinal)
  v_wsupply   <- xts(as.numeric(-wsupply * 86400 / 1000000), order.by = tfinal)
  v_env       <- xts(as.numeric(-env * 86400 / 1000000),     order.by = tfinal)
  
  # annual sum (mm) for evap, percol and pre
  mm_evap     <- xts(as.numeric(evap),   order.by = tfinal)
  mm_percol   <- xts(as.numeric(percol), order.by = tfinal)
  mm_pre      <- xts(as.numeric(pre),    order.by = tfinal)
  yr_mm_evap     <- apply.yearly(mm_evap,   FUN = sum, na.rm=T)
  yr_mm_percol   <- apply.yearly(mm_percol, FUN = sum, na.rm=T)
  yr_mm_pre      <- apply.yearly(mm_pre,    FUN = sum, na.rm=T)
  
  
  # Bind
  v <- cbind(v_inflow, v_pre, v_spill, v_percol, v_evap, v_hydro, v_irrig, v_wsupply, v_env)
  
  
  # Melt
  v_df <- data.frame(v)
  v_df$id <- rownames(v_df)
  v_melted <- melt(v_df, measure.vars=c("v_inflow", "v_pre", "v_spill", "v_percol", "v_evap", "v_hydro", "v_irrig", "v_wsupply", "v_env"))
  V_df <- data.frame(V)
  V_df$id <- rownames(V_df)
  V_melted <- melt(V_df, measure.vars=c("V"))
  h_df <- data.frame(h)
  h_df$id <- rownames(h_df)
  h_melted <- melt(h_df, measure.vars=c("h"))
  # id must be date class
  v_melted$id <- rep(seq.Date(as.Date(tchron[1]),as.Date(tail(tchron, n = 1)), by= "days"), 9)
  V_melted$id <- seq.Date(as.Date(tchron[1]),as.Date(tail(tchron, n = 1)), by= "days")
  h_melted$id <- seq.Date(as.Date(tchron[1]),as.Date(tail(tchron, n = 1)), by= "days")
  
  
  
  
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
  
  
  # Prepare the annual summary annotations
  
  # annotate_sum <- vector("list") # list initialized
  yMax <- max(v_inflow, v_pre, v_spill, v_percol, v_evap, v_hydro, v_irrig, v_wsupply, v_env, na.rm = TRUE)
  
  annual_summary_legend <- function(iyr, posY, color_in){
    legPosX <- as.Date(tfinal[1]) +  ( as.Date(tail(tfinal, n = 1)) - as.Date(tfinal[1]) ) * (iyr - 0.95)/nyrs
    annotate("point", x = legPosX, y = posY, color = color_in)
  }
  
  annual_summary_stat <- function(iyr, posY, data_in){
    statPosX <- as.Date(tfinal[1]) + ( as.Date(tail(tfinal, n = 1)) - as.Date(tfinal[1]) ) * (iyr - 0.9)/nyrs
    annotate("text",  x = statPosX, y = posY, cex = 3.5, label = paste(round(data_in[iyr]), "mm", sep = " "), colour = "black", hjust = 0)
  }
  
  annotate_summary_legend_evap    <- lapply(seq(1, nyrs), function(x) annual_summary_legend(x, yMax * 0.9, use_fill[5]))
  annotate_summary_legend_percol  <- lapply(seq(1, nyrs), function(x) annual_summary_legend(x, yMax * 0.7, use_fill[4]))
  annotate_summary_legend_pre     <- lapply(seq(1, nyrs), function(x) annual_summary_legend(x, yMax * 0.5, use_fill[2]))
  annotate_summary_stat_evap      <- lapply(seq(1, nyrs), function(x) annual_summary_stat(x, yMax * 0.9, yr_mm_evap))
  annotate_summary_stat_percol    <- lapply(seq(1, nyrs), function(x) annual_summary_stat(x, yMax * 0.7, yr_mm_percol))
  annotate_summary_stat_pre       <- lapply(seq(1, nyrs), function(x) annual_summary_stat(x, yMax * 0.5, yr_mm_pre))
  
    
    
  # ========  PLOT  =============================================
  
  
  # Plotting the lake fluxes graph
  
  plot_lake_fluxes <- ggplot() +
    
    # fluxes
    geom_area(data = v_melted, aes( x = id, y = value, fill = as.factor(variable) ), alpha = 1) +
    
    scale_fill_manual(values = use_fill,
                      labels = use_labels) +
    
    labs(title = title_text, subtitle = subtitle_text, caption = caption_text) +
    
    # yearly summary annotations
    annotate_summary_legend_evap +
    annotate_summary_legend_percol +
    annotate_summary_legend_pre +
    annotate_summary_stat_evap +
    annotate_summary_stat_percol +
    annotate_summary_stat_pre +
    
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
    
    scale_y_continuous(name = expression(Flux~volumes~"[x10"^"6"~"m"^"3]"), limits = mylimit , 
                       sec.axis = dup_axis(name ="", label = c()), expand = c(0,0))  # adding extra space at the top for annotations
  
  
  # Plotting the lake states graph
  
  plot_lake_states <- ggplot() +
    
    # states
    geom_area(data = V_melted, aes( x = id, y = value, fill = "lake volume"), alpha = 0.7) +
    
    # DCL volume
    geom_hline(aes(yintercept = dcl_vol, color = "DCL volume"), linetype = 2, size = 2) +
    
    scale_fill_manual(values = c("blue"),
                      labels = c("lake volume")) +
    
    scale_color_manual(values = c("black"),
                       labels = c("DCL volume")) +
    
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
    
    scale_y_continuous(name = expression(State~volumes~"[x10"^"6"~"m"^"3]"), expand = c(0,0))  # adding extra space at the top for annotations
  
  
  # Plotting the lake level graph
  
  plot_lake_level <- ggplot() +
    
    # Level
    geom_line(data = h_melted, aes( x = id, y = value, color = "lake elevation"), alpha = 0.7) +
    
    # DCL
    geom_hline(aes(yintercept = dcl, color = "DCL elevation"), linetype = 2, size = 2) +
    
    scale_color_manual(values = c("blue", "black"),
                       labels = c("lake elevation", "DCL elevation")) +
    
    
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
    
    scale_y_continuous(name = "Elevation [m a.s.l.]", expand = c(0,0))  # adding extra space at the top for annotations
  
  # Output
  ggsave(plot_lake_fluxes, file=paste(path,"/",gID,"_lake_fluxes.png",sep=""), width = 18, height = 5, units = "in")
  ggsave(plot_lake_states, file=paste(path,"/",gID,"_lake_states.png",sep=""), width = 18, height = 5, units = "in")
  ggsave(plot_lake_level, file=paste(path,"/",gID,"_lake_level.png",sep=""), width = 18, height = 5, units = "in")
  
}

