######################################################################################################### 
##                            ---------------------------------------------------------------------------
## ========================== Forecast Scalability Comparision with SCC for reservoirs
##                            ----------------------------------------------------------------------------
## ---------- Code developer: 
## -------------------------  Pallav Kumar Shrestha pallav-kumar.shrestha@ufz.de ------
## -------------------------  5 May 2020 ----------------------------------------
#########################################################################################################

#----------------------------
# Open libraries/ PACKAGES
#----------------------------
library(ggplot2)
library(ncdf4) 
library(lattice)
library(gridExtra)  # for using "grid.arrange" function
library(grid)



# Set the IO directory
iopath_parent = "/Users/shresthp/tmp/eve_data_sawam/sawam/data/processed/mlmdevelopment/mlm_test_area/tests/i150_OFdeltas/03_output/OR_isolated/"

OFfolder <- c("40_dwl_kge", "41_dwl_nse", "42_dwl_sse", 
              "43_v_kge", "44_v_nse", "45_v_sse", 
              "46_dv_kge", "47_dv_nse", "48_dv_sse", 
              "49_dq_kge", "50_dq_nse", "51_dq_sse" )

OFtitle <- c("dWL KGE optimized", "dWL NSE optimized", "dWL SSE optimized",
             "V KGE optimized", "V NSE optimized", "V SSE optimized",
             "dV KGE optimized", "dV NSE optimized", "dV SSE optimized",
             "dQ KGE optimized", "dQ NSE optimized", "dQ SSE optimized")




#----------------------------
# VARIABLES 
#----------------------------
branch <- c("fork_mlm", "fork_scc")
namebranch <- c("without SCC", "with SCC")
# 
# lakes  <- c("SerraAzul", "PocoDaCruz", "TresMarias", "Sobradinho")
# namelakes <- c(as.expression(expression( paste("Serra Azul (c.a. 256 ", km^2, ")"))),
#                as.expression(expression( paste("Poco da Cruz (c.a. 4,850 ", km^2, ")"))),
#                as.expression(expression( paste("Trés Marias (c.a. 50,816 ", km^2,")"))),
#                as.expression(expression( paste("Sobradinho (c.a. 500,632 ", km^2,")"))))
lakes  <- c("SerraAzul", "PocoDaCruz", "Oros", "Acu", "TresMarias", "Sobradinho", "Itaparica")
namelakes <- c(as.expression(expression( paste("Serra Azul (c.a. 256 ", km^2, ")"))),
               as.expression(expression( paste("Poco da Cruz (c.a. 4,850 ", km^2, ")"))),
               as.expression(expression( paste("Orós (c.a. 25,028 ", km^2,")"))),
               as.expression(expression( paste("Açu (c.a. 37,242 ", km^2,")"))),
               as.expression(expression( paste("Trés Marias (c.a. 50,816 ", km^2,")"))),
               as.expression(expression( paste("Sobradinho (c.a. 500,632 ", km^2,")"))),
               as.expression(expression( paste("Itaparica (c.a. 594,829 ", km^2,")"))))

ensemble_stats <- c("ensmaxForecast", "ensminForecast", "ensmedianForecast")
ensemble_stats_names <- c("ens max", "ens min", "ens median")


spread_limits <- c("ensmaxScale", "ensminScale")
spread_limits_colnames <- c("smax", "smin")

nbranches <- length(branch)
nlakes <- length(lakes)
nensstats <- length(ensemble_stats)
nspreadlimits <- length(spread_limits)



#----------------------------
# Defining MULTIPLOT lists
#----------------------------
plots <- list()
nColPlot <- nlakes
nRowPlot <- nbranches


#-----------------------------
# Defining COLORS & VISIBILITY
#-----------------------------
ensmax_clr <- rgb(0/255, 118/255, 186/255, alpha = 0.8)
ensmedian_clr <-rgb(146/255, 146/255, 146/255, alpha = 0.8)
ensmin_clr <-rgb(248/255, 186/255, 0/255, alpha = 0.8)

# label colors for (in)visibility
xlabel_clr <- c("white", "black")
ylabel_clr <- c("black", rep("white", nlakes - 1))
title_select <- c(namelakes, rep("", nlakes))


#----------------------------
# Initialize graph axes LIMITS
#----------------------------
ylimit <- matrix(rep(0, nlakes*nbranches), nrow = nbranches, ncol = nlakes)
ymax_limit <- c(rep(0, nlakes))


#----------------------------
# Construct the DATAFRAME
#----------------------------

for (ibranch in 1:nbranches) { # ==================== branch loop

  for (ilake in 1:nlakes) { # ======================= lake loop
      
      for (iensstat in 1:nensstats) { # ===================== ens stat loop 
        
        
        # prepare SUB-DATAFRAME with 7 rows
        df_sub <- data.frame(row.names = c(seq(1,7)))
        # add lead months to the dataframe
        lmonth <- c(seq(0,6))
        df_sub <- cbind(df_sub, lmonth)
        
        
        for (ispreadlimit in 1:nspreadlimits) { # =================== scale spread loop 
          
          # netCDF file name
          fname <- paste(iopath,"08_forecast_multiscale_v2/", branch[ibranch], "/mLM_Fluxes_States_", lakes[ilake], 
                         "_LQin_", ensemble_stats[iensstat], "_", spread_limits[ispreadlimit], ".nc", sep = "")
          
          # read the data
          ncin_mlm <- nc_open(fname)
          
          # store variable and give reference name "type"
          tmp.vector <- ncvar_get(ncin_mlm,"LQin") 
          tmp.vector <- tmp.vector[1:7]
          
          # append to the data frame with corresponding headers
          df_sub <- cbind(df_sub, tmp.vector)
          colnames(df_sub)[ispreadlimit+1] <- spread_limits_colnames[ispreadlimit]
          
          
        }  # =================== scale spread loop 
        
        
        # Group the current ensemble stat
        df_sub$statistic <- ensemble_stats_names[iensstat]
        
        # Merge the sub data frame to main data frame
        if (iensstat == 1) {
          df_main <- df_sub
        } else {
          df_main <-rbind(df_main, df_sub)  
        }
        
    
      } # =================== ens stat loop 
    
    
    
      # Get limit for y axis
      print(paste(ibranch, ilake))
      ylimit[ibranch, ilake] <- max(df_main$smax) # limit of current dataframe
      ymax_limit[ilake] <- 1.1 * max(ylimit[,ilake])
      print(paste(ibranch, ilake, ylimit[ibranch, ilake], ymax_limit[ilake]))
    

      # Make the PLOT OBJECT
      xplot <- ggplot(data=df_main, aes(x=lmonth, ymin=smin, ymax=smax, fill=statistic, linetype=statistic)) + 
        geom_ribbon() + 
        scale_fill_manual(values=c(ensmax_clr, ensmedian_clr, ensmin_clr)) +
        
        # Labels
        xlab(as.expression(expression( paste("lead time (months)") ))) + 
        ylab(as.expression(expression( paste("avg. reservoir inflow (", m^3, s^{-1},")")))) +
        labs(title = title_select[(ibranch-1)*nlakes + ilake], 
             subtitle = namebranch[ibranch])+
        # Axes
        scale_x_continuous(breaks = c(seq(0,6)), limits = c(0,6)) +
        scale_y_continuous(limits = c(0,ymax_limit[ilake])) +
        
        # Theme control
        theme(text=element_text(family = "Helvetica"), 
              axis.ticks.length=unit(-0.25, "cm"), 
              axis.text.x = element_text(margin = margin(t = 10), size = 15), 
              axis.text.y = element_text(margin = margin(r = 10), size = 15), 
              axis.title.y = element_text(margin = margin(r = 10), size = 20, colour = ylabel_clr[ilake]), 
              axis.title.x = element_text(margin = margin(t = 20), size = 20, colour = xlabel_clr[ibranch]), 
              panel.grid.major.x = element_line(linetype = "solid", colour = "grey94", size = 0.5),
              panel.grid.major.y = element_line(linetype = "solid", colour = "grey94", size = 0.5),
              panel.border = element_rect(colour = "black", fill=NA, size=1), 
              panel.background = element_blank(),
              legend.position = c(0.8, 0.8), 
              legend.text = element_text(size = 15),
              legend.title = element_blank(),
              plot.title = element_text(size = 30), 
              plot.subtitle = element_text(size = 20, face = "bold"),
              plot.margin = unit(c(0, 0.5, 0, 0.5), "cm") )

      
      # Append to multiplot 
      xplot <- ggplotGrob(xplot)
      plots[[ilake+(ibranch-1)*nlakes]] <- xplot  
      
  } # ======================= lake loop
} # ==================== branch loop


#--------------------------------
# Construct the MULTIPLOT & SAVE
#--------------------------------

# Defining the layout of the multiplot
xlay <- matrix(c(1:(nColPlot*nRowPlot)), nRowPlot, nColPlot, byrow = TRUE)

select_grobs <- function(lay) {
  id <- unique(c(t(lay))) # transpose ON if byrow = TRUE in xlay! If not, remove transpose!
  # id <- unique(c(t(lay))) 
  id[!is.na(id)]
}


# Output
pdf("forecast_scalability_w_wo_SCC.pdf", width = 7*nColPlot, height = 5*nRowPlot) # each subplot is 5x5 inches

grid.arrange(grobs=plots[select_grobs(xlay)], layout_matrix=xlay)

# Close PDF
dev.off()