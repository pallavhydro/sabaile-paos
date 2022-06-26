
library(xts) 



# Read raw file
data_raw <- read.delim("rappbo bathy.txt", sep = ",")

ncols <- length(unique(data_raw$X))
nrows <- length(unique(data_raw$Y))


# initialize (2D) as cols x rows for storing data
data_array <- data.frame(matrix(data = NA, nrow = ncols, ncol = 0))


for (iy in 1:nrows){
  
  sindex     <- (iy-1) * ncols + 1
  eindex     <- sindex + ncols - 1
  data_row   <- data_raw$rappbo[sindex : eindex]
  data_array <- cbind(data_array, data_row)
  
}

data_array <- t(data_array) # transpose to get correct array

data <- as.matrix(data_array[1:nrows, 1:ncols])


# Write to file
write.table(data_array, file="rappbo_bathy.asc", sep=" ", row.names = FALSE, col.names = FALSE, quote = FALSE)
