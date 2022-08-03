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



plot_hydrographx2 <- function(opath, file1, file2, suffix1, suffix2, gID, title_text , ylimit ){


  # ========  CONTROL  =============================================
  
  # Parameters
  misVal = -9999.0
  
  # Graph control
  use_labels <- c("observed", paste("mHM_", suffix1, sep=""), paste("mHM_", suffix2, sep="") )
  use_colors <- c("red", "blue", "black")
  use_linetypes <- c(2, 1, 1)
  
  
  # ========  READ  =============================================
  
  # Read the netCDF discharge file 1
  ncin <- nc_open(file1)
  # get VARIABLES
  q_obs1 <- ncvar_get(ncin, paste("Qobs_", str_pad(gID, 10, pad = "0"), sep = ""))
  q_sim1 <- ncvar_get(ncin, paste("Qsim_", str_pad(gID, 10, pad = "0"), sep = ""))
  # Read time attribute
  nctime <- ncvar_get(ncin,"time")
  tunits <- ncatt_get(ncin,"time","units")
  nt <- dim(nctime)
  # Close file
  nc_close(ncin)
  
  
  # Read the netCDF discharge file 1
  ncin <- nc_open(file2)
  # get VARIABLES
  q_sim2 <- ncvar_get(ncin, paste("Qsim_", str_pad(gID, 10, pad = "0"), sep = ""))
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

  # Replacing missing values by NA
  q_obs1[q_obs1 == misVal] <- NA
  q_sim1[q_sim1 == misVal] <- NA
  q_sim2[q_sim2 == misVal] <- NA

  # convert to xts
  q_obs1 <- xts(as.numeric(q_obs1), order.by = tchron) # xts/ time series object created
  q_sim1 <- xts(as.numeric(q_sim1), order.by = tchron)
  q_sim2 <- xts(as.numeric(q_sim2), order.by = tchron)
  
  
  # Bind
  q <- cbind(q_obs1, q_sim1, q_sim2)
  # Melt
  q_df <- data.frame(q)
  q_df$id <- rownames(q_df)
  q_melted <- melt(q_df, measure.vars=c("q_obs1", "q_sim1", "q_sim2"))
  # id must be date class
  q_melted$id <- rep(seq.Date(as.Date(tchron[1]),as.Date(tail(tchron, n = 1)), by= "days"), 3)
  
  
  # Preparing METRICS annotations for the graph
  statKGE1 <- round(KGE(q_sim1,q_obs1,na.rm = TRUE),2)  # KGE 
  statNSE1 <- round(NSeff(q_sim1,q_obs1,na.rm = TRUE),2)  # NSE
  statPBS1 <- round(pbias(q_sim1,q_obs1,na.rm = TRUE),2)  # PBIAS
  statKGE2 <- round(KGE(q_sim2,q_obs1,na.rm = TRUE),2)  # KGE 
  statNSE2 <- round(NSeff(q_sim2,q_obs1,na.rm = TRUE),2)  # NSE
  statPBS2 <- round(pbias(q_sim2,q_obs1,na.rm = TRUE),2)  # PBIAS
  
 
  qmax <- max(q_obs1, q_sim1, q_sim2, na.rm = TRUE)
  
  # y limit
  if (missing(ylimit)){
    mylimit = NULL
  } else {
    mylimit = c(0, ylimit)
    qmax = ylimit
  }
  
  
  
  # adjust pdf width for long hydrographs
  nyrs = as.numeric(format(tail(tchron, n = 1),'%Y')) - as.numeric(format(tchron[1],'%Y')) + 1
  if (nyrs > 10){
    mydatebreaks = "5 years"
    pdf_width = 12 + (nyrs - 10)
  } else {
    mydatebreaks = "1 year"
    pdf_width = 12
  }
  
  
  # ========  PLOT  =============================================

  date_range = paste(as.numeric(format(tchron[1],'%Y')), as.numeric(format(tail(tchron, n = 1),'%Y')), sep = "-")
  caption_text <- paste(paste("KGE_", suffix1, sep = ""),": ", statKGE1, "     ", 
                        paste("NSE_", suffix1, sep = ""),": ", statNSE1, "     ", 
                        paste("PBIAS_", suffix1, sep = ""),": ", statPBS1, " %\n", 
                        paste("KGE_", suffix2, sep = ""),": ", statKGE2, "     ", 
                        paste("NSE_", suffix2, sep = ""),": ", statNSE2, "     ", 
                        paste("PBIAS_", suffix2, sep = ""),": ", statPBS2, " %"
                        )



  # Plotting the hydrograph

  
  hydrograph <- ggplot() +
    # hydrographs
    geom_line(data = q_melted, aes( x = id, y = value, color = as.factor(variable), linetype = as.factor(variable) ), size = 1, alpha = 1) +
    
    scale_color_manual(values = use_colors,
                       labels = use_labels) +
    
    scale_linetype_manual(values = use_linetypes,
                          labels = use_labels) +
    

    labs(title = title_text, caption = caption_text) +
    
    theme(
      text=element_text(family = "Helvetica", colour = "black"),
      axis.ticks.length=unit(-0.2, "cm"),
      axis.ticks = element_line(colour = "black", size = 0.5),
      axis.text.x = element_text(size=14, margin = margin(t = 10), colour = "black"),
      axis.title.x = element_text(size=16, margin = margin(t = 10), colour = "black"),
      axis.text.y = element_text(size=14, margin = margin(r = 10), colour = "black"),
      axis.title.y.left  = element_text(size=16, margin = margin(r = 15), colour = "black", hjust = c(0.5)),
      axis.title.y.right = element_blank(),
      plot.title = element_text(size = 16, colour = "black", hjust = c(0), margin = margin(b = -50, t = 10), face = "bold"),
      plot.caption = element_text(size = 16, colour = "black", hjust = c(1)),
      panel.border = element_rect(colour = "black", fill=NA, size=1),
      panel.background = element_blank(),
      panel.grid.major = element_line(colour = alpha("black", 0.5), size=0.2, linetype = 3),
      legend.position = "top",
      legend.key = element_blank(),
      legend.key.height = unit(1, "cm"),
      legend.key.width = unit(1.5, "cm"),
      legend.spacing.y = unit(0, "cm"),
      legend.box.margin = margin(t = 20, unit = "pt"),
      legend.text = element_text(size=16, colour = "black", hjust = c(0), margin = margin(r = 30, unit = "pt")),
      legend.title = element_blank(),
      legend.background = element_blank()) +
    
    scale_x_date(name = "Time", date_breaks= mydatebreaks, date_labels = "%Y", expand = c(0,0)) + # duplicating the axis for the top was not possible with date axis
  
    scale_y_continuous(name = expression(paste("Streamflow [",m^{3},".",s^{-1},"]")), limits = mylimit , sec.axis = dup_axis(name ="", labels = c()), expand = c(0,0))  # adding extra space at the top for annotations
  
  # Output
  ggsave(hydrograph, file=paste(opath, "/", gID, ".png",sep=""), width = 18, height = 5, units = "in")

}


