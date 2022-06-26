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

# Parameters
lat_max       = 90
lat_int       = 1


# Initialize Year Time Axis
tchron <- as.POSIXct(chron(dates. = seq(0,364), origin=c(1, 1, 2001)), "GMT", origin=paste(2001,1,1, sep = "-"))
# Initialize (2D)
albedo_water_frs <- data.frame(matrix(data = NA, nrow = YearDays, ncol = 2*lat_max/lat_int + 1))
albedo_water_calc <- albedo_water_frs
elevation_angle <- albedo_water_frs




##  --  CALCULATE ALBEDO  --

# Loop over DOY
for (doy in seq(1, YearDays)){
  
  # Loop over Latitudes
  for (lat in seq(-lat_max, lat_max, lat_int)){
    
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
    # 
    # # Constrain the estimated albedo
    # if (albedo_water < albedo_w_low){
    #   albedo_water = albedo_w_low
    # }
    # if (albedo_water > albedo_w_high){
    #   albedo_water = albedo_w_high
    # }
    
    # Estimate water albedo from Grishchenko dataset
    E = E * rad2deg # E >0 needed
    if (E < 0){ # E >0 needed
      E = 0 # sun is below horizon already!
    }
    albedo_water = (grishchenko_s*((grishchenko_k/grishchenko_l) * ((E/10/grishchenko_l)^(grishchenko_k-1)) * exp(- (E/10/grishchenko_l)^grishchenko_k)) + grishchenko_c) / 100
    
    # # Store
    elevation_angle [doy, (lat + lat_max)/lat_int + 1] <- E # Solar Elevation Angle
    # albedo_water_frs[doy, lat + lat_max + 1] <- albedo_water # Water albedo
    
    
    
    
    # Store
    albedo_water_calc[doy, (lat + lat_max)/lat_int + 1] <- albedo_water
    
  }
  
}

# Melt
albedo_water_calc_df <- data.frame(albedo_water_calc)
albedo_water_calc_df$id <- rownames(albedo_water_calc_df)
albedo_water_calc_melted <- melt(albedo_water_calc_df)
albedo_water_calc_melted$id <- rep(seq.Date(as.Date(tchron[1]),as.Date(tail(tchron, n = 1)), by= "days"), 2*lat_max/lat_int + 1)
albedo_water_calc_melted$lat <- (as.numeric(substr(albedo_water_calc_melted$variable, 2, 100)) - 1)*lat_int - lat_max

# Latitude colors
# colors_latitude <- colorspace::diverge_hsv(2*lat_max/lat_int + 1)
# colors_latitude <- colorRamps::blue2red(2*lat_max/lat_int + 1)
colors_latitude <- colorRampPalette(c("blue", "purple", "red", "grey", "orange", "brown", "black"))(2*lat_max/lat_int + 1)
# barplot(rep(1, 10), col = colorRampPalette(c("blue", "springgreen", "red"))(2*lat_max/lat_int + 1))
colors_albedo <- colorRampPalette(c("blue", "purple", "red", "grey", "orange", "brown", "black"))(100)


##  --  PLOT ALBEDO  --

plot_timeseries_line(albedo_water_calc_melted, ".", paste("alb_across_", lat_int, "_degree_latitudes_grishchenko.pdf", sep = ""), 
                     paste("Albedo seasonality for water at ", lat_int, " degree latitudes"), "lake albedo [-]", colors_latitude, 0.5,
                     c(seq(-lat_max, lat_max)),
                     "none", "1 month", "%b", c(0, 0.6))


# Tile plot. Albedo = f(lat, doy)
ggplot(albedo_water_calc_melted, aes(x = lat, y = id)) + geom_tile(aes(fill = value)) + 
  scale_fill_viridis_b(name = "Albedo", trans = "atanh") +#,
                       # breaks = c(0.01, 0.02, 0.03, 0.04, 0.05, 0.1, 0.2, 0.4),
                       # labels = c("0.01", "0.02", "0.03", "0.04", "0.05", "0.1", "0.2", "0.4")) +
  # scale_fill_stepsn(aesthetics = "colour", colours = colors_albedo) +
  scale_y_date(name = "Time", date_breaks = "1 month", date_labels = "%b", expand = c(0,0)) +
  scale_x_continuous(name = "Latitude", breaks = c(seq(-lat_max, lat_max, 30)))


