####################################################

#  Program to calculate Water Albedo varying with
#  Latitude and DOY using Fresnel's equation

#  Pallav Kumar Shrestha, Feb 2022

# Mods: PKS Mar 2022 - added Grishchenko
####################################################

library(reshape) # for melt
library(chron)
library(viridis)
# Source taylor-made functions
source("metrics_across_domains.R")
source("timeseries_line.R")

# Constants
DuffieDelta1  = 0.4090
DuffieDelta2  = 1.3900
grishchenko_k = 1.517
grishchenko_l = 1.236
grishchenko_s = 53.279
grishchenko_c = 4.493
RefracIndex_w = 1.33  
fresnel_c     = 50
albedo_w_low  = 0.025
albedo_w_high = 0.5
YearDays      = 365
deg2rad       = pi/180
rad2deg       = 180/pi




# LUT file of dams
lut_file= "/Users/shresthp/tmp/Win7/global_mlm/selection/atable_mlm_global_dam_selection_v1_tm_adj_v3.csv"
# Read LUT file
lut_data <- read.delim(lut_file, sep = "," , header = TRUE )
ndomains = length(lut_data$station_id)


# Initialize Year Time Axis
tchron <- as.POSIXct(chron(dates. = seq(0,364), origin=c(1, 1, 2001)), "GMT", origin=paste(2001,1,1, sep = "-"))
# Initialize (2D)
albedo_water_frs <- data.frame(matrix(data = NA, nrow = YearDays, ncol = ndomains))
albedo_water_cut <- albedo_water_frs
elevation_angle <- albedo_water_frs




##  --  CALCULATE ALBEDO  --

# Loop over DOY
for (doy in seq(1, YearDays)){
  
  # Loop over dams
  for (idomain in seq(1, ndomains)){
    
    lat <- lut_data$Latitude[idomain]
    
    # Angle of declination (radians)
    delta <- DuffieDelta1 * sin(2*pi * doy / YearDays - DuffieDelta2)
    
    # Solar Inclination angle (radians)
    E = asin( sin(lat*deg2rad) * sin(delta) + cos(lat*deg2rad) * cos(delta) ) 
    # PS - assuming the daily value at noon, h is 0 degree ie cos(h) reduces to 1
    
    # Solar Zenith angle (radians)
    Z = pi/2 - E
    
    # Get angle of refraction of water from Snell's Law (radians)
    r = asin(sin(Z) / RefracIndex_w)
    
    # # Estimate water albedo from Fresnel's formula
    # albedo_water = fresnel_c * ( ( sin(Z - r)^2 / sin(Z + r)^2 ) + ( tan(Z - r)^2 / tan(Z + r)^2 ) ) / 100
    
    # # Constrain the estimated albedo
    # if (albedo_water < albedo_w_low){ 
    #   albedo_water = albedo_w_low
    # }
    # if (albedo_water > albedo_w_high){
    #   albedo_water = albedo_w_high
    # }
    
    # Estimate water albedo from Grishchenko dataset
    print(paste(idomain, Z * rad2deg))
    E = E * rad2deg 
    if (E >= 0){
      albedo_water = (grishchenko_s*((grishchenko_k/grishchenko_l) * ((E/10/grishchenko_l)^(grishchenko_k-1)) * exp(- (E/10/grishchenko_l)^grishchenko_k)) + grishchenko_c) / 100
    } else {
      albedo_water = 0 # sun is below horizon
    }
    
    # Store
    elevation_angle [doy, idomain] <- E # Solar Elevation Angle
    # albedo_water_frs[doy, idomain] <- albedo_water # Water albedo
    
    # Store
    albedo_water_cut[doy, idomain] <- albedo_water
    
  }
  
}

# Melt
albedo_water_cut_df <- data.frame(albedo_water_cut)
albedo_water_cut_df$id <- rownames(albedo_water_cut_df)
albedo_water_cut_melted <- melt(albedo_water_cut_df)
albedo_water_cut_melted$id <- rep(seq.Date(as.Date(tchron[1]),as.Date(tail(tchron, n = 1)), by= "days"), ndomains)

# Latitude colors
colors_latitude <- colorspace::diverge_hsv(ndomains)
colors_latitude <- rep("blue", ndomains)



##  --  PLOT ALBEDO  --

plot_timeseries_line(albedo_water_cut_melted, ".", "alb_across_lut_grishchenko.pdf", 
                     "Albedo seasonality for water at each lake", "lake albedo [-]", colors_latitude, 0.75,
                     c(seq(1, ndomains)), 
                     "none", "1 month", "%b", c(0, 0.6))


