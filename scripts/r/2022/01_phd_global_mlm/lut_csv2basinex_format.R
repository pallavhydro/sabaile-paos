######################################################################################################### 
##                            ---------------------------------------------------------------------------
## ========================== LUT formatting: arcgis csv to basinex format
##                            ----------------------------------------------------------------------------
## ---------- Code developer: 
## -------------------------  Pallav Kumar Shrestha pallav-kumar.shrestha@ufz.de ------
## -------------------------  13 July 2022 ----------------------------------------
#########################################################################################################

#### Gives one set of skill scores for the whole simulation period


# Open libraries/ packages

  library(zoo)



  
  # ========  CONTROL  =============================================
  
  # Command line arguments (1 - file name without extension)
  args <- commandArgs(trailingOnly = TRUE)

  # Parameters
  fName = args[1]
  
  # fName = "grand_dams_v1_3_clip.csv"
  
  
  
  # ========  READ  =============================================
  
  # Read the Arcgis csv file
  table <- read.csv(fName, header = T)
  
  
  
  
  # ========  PROCESS  =============================================


  # Subset table
  table_subset <- table[, 2:length(table[1,])]
  
  # Update col headers
  colnames(table_subset) <- c("id", "size", "x", "y")
  
  # Update order of col headers
  table_final <- data.frame(table_subset[,c(1, 2, 4, 3)])
  
  

    
  # ========  SAVE TO CSV =============================================

  fName_out <- paste(unlist(strsplit(fName, ".csv"))[1], ".txt", sep = "")

  write.table(table_final, file=fName_out, sep=";", quote = F, row.names = F)

  
