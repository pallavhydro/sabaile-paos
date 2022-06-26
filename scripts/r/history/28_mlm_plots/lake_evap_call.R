######################################################################################################### 
##
## ========================== Lake Evaporation call script
##
#########################################################################################################


# Source taylor-made functions
source("plot_lake_evap_methods.R")


path <- "."
branch <- "SCC" #"@branch@"
resolution <- "0p25" # "@res@"
dam_param <- "default" #"@damparam@"
non_dam_param <- "default" #"@nondamparam@"
simperiod <- "" #"calibration" #"@simperiod@"
path_suffix <- paste(branch, resolution, "output", substring(simperiod, 1, 3), sep = "/")
file_suffix <- paste(branch, resolution, substring(simperiod, 1, 3), sep = "_")


title_text <- paste("period:", simperiod)
caption_text <- paste("dam parameters: ", dam_param, "    .    non-dam parameters: ", non_dam_param)
  
plot_lake_evap(path, path_suffix, file_suffix, title_text, caption_text )

