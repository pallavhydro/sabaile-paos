#####################################################################################
##                   ----------------------------------------------------------------
## ==================== Correcting EVA curves from Yigzaw (2018) WRR
##                   ----------------------------------------------------------------
## --- Code developer: 
## ------------------  Pallav Kumar Shrestha pallav-kumar.shrestha@ufz.de ------
## ------------------  22 Sep 2021 ---------------------------------------------
##
## --- Mods: 
##          xx xxx xxxx - xxxx 
#####################################################################################


wdir <- "~/Nextcloud/Cloud/macbook/01_work/eve/data_from_eve/01_mlm_paper/correcting_yigzaw_eva_curves/"
# wdir <- "~/Nextcloud/Cloud/macbook/01_work/eve/data_from_eve/01_mlm_paper/test/"


# All files 
files<-list.files(path=paste(wdir, "raw", sep = "/"), pattern='.csv', full.names = FALSE)


# Loop over all files

for (eva_file in files){

  # Construct I/O files
  eva_file_in <- paste(wdir, "raw", eva_file, sep = "/")
  eva_file_out<- paste(wdir, "processed", eva_file, sep = "/")
  
  # Read EVA file header lines
  eva_header <- read.delim(eva_file_in, sep = ";", header = FALSE, nrows = 8 )
  
  # Read EVA file table
  eva_data <- read.delim(eva_file_in, sep = "," , header = TRUE, skip = 7 )
  
  # Remove all entries with duplicate repeating volume, keeping only the last entry
  eva_data_unique_vol <- eva_data[!duplicated(eva_data[ , c("Storage.mcm.")], fromLast = TRUE),]
  
  # # Remove all entries with duplicate surface area, keeping only the last entry
  # eva_data_unique_vol_sa <- eva_data_unique_vol[!duplicated(eva_data_unique_vol[ , c("Area.skm.")], fromLast = TRUE),]
  
  # Print the corrected data to file
  write.table(eva_header, eva_file_out, append=FALSE, row.names = FALSE, col.names = FALSE, quote = FALSE)
  write.table(eva_data_unique_vol, eva_file_out, append=TRUE, sep = ",", row.names = FALSE, col.names = FALSE, quote = FALSE)
  
  print(eva_file)
  
}


