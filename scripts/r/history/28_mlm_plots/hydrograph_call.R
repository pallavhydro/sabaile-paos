######################################################################################################### 
##
## ========================== Hydrograph call script
##
#########################################################################################################


# Source taylor-made functions
source("hydrograph.R")


path <- "."
dam_name <- "@name@"
dam_country <- "@damcountry@"
station_id <- "@id@" #"41020002"
dam_id <- "@damid@" 
dam_sa <- "@damsa@" 
dam_param <- "@damparam@"
non_dam_param <- "@nondamparam@"
dam_vol <- @damvol@
dam_ca <- @damca@
dam_ca_ratio <- @damcaratio@
simperiod <- "@simperiod@"


title_text <- paste("dam: ", dam_name, " (", dam_country, ")", "    .    gauge:", station_id, "    .    period:", simperiod)
subtitle_text <- bquote("dam V: " ~ .(dam_vol) ~ x10^6 ~ m^3 ~ "    .    max lake area: " ~ .(dam_sa) ~ x10^6 ~ m^2 ~ "    .    c.a.:" ~ .(dam_ca) ~ x10^6 ~ m^2 ~ "    .    c.a. ratio: " ~ .(dam_ca_ratio))
caption_text <- paste("dam parameters: ", dam_param, "    .    non-dam parameters: ", non_dam_param)
  
plot_hydrograph(path, station_id,  title_text, subtitle_text, caption_text )

