######################################################################################################### 
##                            ---------------------------------------------------------------------------
## ========================== Hydrograph Generation from mHM streamflow output (discharge.nc)
##                            ----------------------------------------------------------------------------
## ---------- Code developer: 
## -------------------------  Pallav Kumar Shrestha pallav-kumar.shrestha@ufz.de ------
## -------------------------  07 October 2021 ----------------------------------------
#########################################################################################################

#### Gives one set of skill scores for the whole simulation period


# Open libraries/ packages
library(ggplot2)
library(VIC5)     # for using fucntion logNSE
library(hydroGOF) # for using fucntions KGE and NSE
library(ncdf4) 
library(chron)
library(xts) 
library(reshape) # for melt
library(stringr) # for str_pad
library(ragg)    # for scaling plot



plot_hydrograph <- function(path, gID, title_text, subtitle_text, caption_text, ylimit ){


  # ========  CONTROL  =============================================
  
  # Parameters
  fName = "discharge.nc"
  # fName = "discharge_1967_1971.nc"
  misVal = -9999.0
  
  # Graph control
  use_labels <- c("observed", "mHM")
  use_colors <- c("red", "blue")
  use_linetypes <- c(2, 1)
  
  
  # ========  READ  =============================================
  
  # Read the netCDF discharge file
  ncin <- nc_open(paste(path,fName,sep = "/"))
  # get VARIABLES
  q_obs <- ncvar_get(ncin, paste("Qobs_", str_pad(gID, 10, pad = "0"), sep = ""))
  q_sim <- ncvar_get(ncin, paste("Qsim_", str_pad(gID, 10, pad = "0"), sep = ""))
  q_obs[q_obs == misVal] <- NA
  q_dif <- q_sim - q_obs
  q_dif[is.na(q_dif)] <- 0 # to avoid artefact in delta Q plot

  ymin <- min(min(q_sim, na.rm = TRUE), min(q_obs, na.rm = TRUE))
  ymax <- max(max(q_sim, na.rm = TRUE), max(q_obs, na.rm = TRUE))


  q_obs_2 <- q_obs
  q_sim_2 <- q_sim
  q_obs_2[q_obs_2 <= 0] <- NA
  q_sim_2[q_sim_2 <= 0] <- NA
  # if (metric1 == "logNSE"){
  #   q_obs[q_obs == 0] <- NA # to avoid the log(0) issue
  # }
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
  
  # convert to xts
  q_obs <- xts(as.numeric(q_obs), order.by = tfinal) # xts/ time series object created
  q_sim <- xts(as.numeric(q_sim), order.by = tfinal)
  q_dif <- xts(as.numeric(q_dif), order.by = tfinal)
  
  
  # Bind
  q <- cbind(q_obs, q_sim)
  # Melt
  q_df <- data.frame(q)
  q_df$id <- rownames(q_df)
  q_melted <- melt(q_df, measure.vars=c("q_obs", "q_sim"))
  q_dif_df <- data.frame(q_dif)
  q_dif_df$id <- rownames(q_dif_df)
  q_dif_melted <- melt(q_dif_df, measure.vars=c("q_dif"))
  # id must be date class
  q_melted$id <- rep(seq.Date(as.Date(tfinal[1]),as.Date(tail(tfinal, n = 1)), by= "days"), 2)
  q_dif_melted$id <- seq.Date(as.Date(tfinal[1]),as.Date(tail(tfinal, n = 1)), by= "days")
  
  
  # Preparing METRICS annotations for the graph
  statKGE <- round(KGE(q_sim,q_obs,na.rm = TRUE),2)  # KGE 
  kge_terms <- as.numeric(unlist(KGE(q_sim, q_obs, na.rm = TRUE, out.type = "full")[2]))
  statKGEgamma <- round(kge_terms[1], 2)
  statKGEbeta  <- round(kge_terms[2], 2)
  statKGEalpha <- round(kge_terms[3], 2)
  # statlogNSE <- round(NSE(log(q_obs), log(q_sim), na.rm = TRUE),2)  # logNSE
  statlogNSE <- round(logNSE(q_sim_2, q_obs_2),2)  # logNSE
  statNSE <- round(NSeff(q_sim,q_obs,na.rm = TRUE),2)  # NSE
  statPBS <- round(pbias(q_sim,q_obs,na.rm = TRUE),2)  # PBIAS
  
  statPosX1 <- 
             # start date
             as.Date(tfinal[1]) +
             # date window
             ( as.Date(tail(tfinal, n = 1)) - as.Date(tfinal[1]) ) *
             # start date as fraction of window
             0.09
  statPosX2 <- 
            # start date
            as.Date(tfinal[1]) +
            # date window
            ( as.Date(tail(tfinal, n = 1)) - as.Date(tfinal[1]) ) *
            # start date as fraction of window
            0.25
  qmax <- max(q_obs, q_sim, na.rm = TRUE)
  
  # y limit
  if (missing(ylimit)){
    mylimit = NULL
  } else {
    mylimit = c(0, ylimit)
    qmax = ylimit
  }
  
  statPosY1 <- qmax*0.9   # determining position for statistics
  statPosY2 <- qmax*0.8
  statPosY3 <- qmax*0.7
  statPosY4 <- qmax*0.6
  
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
  

  # Plotting the delta hydrograph
  
  hydrograph_diff <- ggplot() +

    # diff hydrographs
    geom_area(data = q_dif_melted, aes( x = id, y = value, fill = "Qdiff"), alpha = 1) +
    
    scale_fill_manual(values = "grey",
                       labels = "Qdiff") +
    

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
    
    scale_x_date(name = "Time", date_breaks= mydatebreaks, date_labels = "%Y", expand = c(0,0), limits = c(q_dif_melted$id[1], q_dif_melted$id[length(q_dif_melted$id)])) + # duplicating the axis for the top was not possible with date axis
  
    scale_y_continuous(name = bquote(Delta ~ "Streamflow [" ~ m^3 ~ "." ~ s^{-1} ~ "]"), limits = c(min(q_dif, na.rm = TRUE), ymax) , sec.axis = dup_axis(name ="", labels = c()), expand = c(0,0))  # adding extra space at the top for annotations
  

  # Plotting the hydrograph

  subtitle_text <- bquote(atop(.(subtitle_text),
                        "logNSE " ~ .(statlogNSE) ~ "    .    "~
                        "NSE " ~ .(statNSE) ~"    .    " ~
                        "KGE " ~ .(statKGE) ~"    .    " ~
                        gamma ~ .(statKGEgamma) ~"    .    "~
                        beta ~ .(statKGEbeta) ~"    .    "~
                        alpha ~ .(statKGEalpha) ~"    .    "~
                        "pbias " ~ .(statPBS, " %")))
  
  
  hydrograph <- ggplot() +
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
      legend.text = element_text(size=14, colour = "black", hjust = c(0)),
      legend.title = element_blank(),
      legend.background = element_blank()) +
    
    scale_x_date(name = "Time", date_breaks= mydatebreaks, date_labels = "%Y", expand = c(0,0)) + # duplicating the axis for the top was not possible with date axis
  
    scale_y_continuous(name = expression(paste("Streamflow [",m^{3},".",s^{-1},"]")), limits = mylimit , sec.axis = dup_axis(name ="", labels = c()), expand = c(0,0))  # adding extra space at the top for annotations
  
  # Output
  ggsave(hydrograph, file=paste(path,"/",gID,"_hydrograph.png",sep=""), width = 18, height = 5, units = "in")
  ggsave(hydrograph_diff, file=paste(path,"/",gID,"_hydrograph_diff.png",sep=""), width = 18, height = 5, units = "in")

}


