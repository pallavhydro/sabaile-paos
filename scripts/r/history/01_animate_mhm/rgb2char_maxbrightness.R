###################################################################################################
##                   -------------------------------------------
## ==================   Convert .rgb file to character vector colors    ===================================
##                   -------------------------------------------
##   
##  Author:    Pallav Kumar Shrestha    (pallav-kumar.shrestha@ufz.de)
##             02 June 2019
##
##  Usage:     Rscript rgb2char.R
##
##  Output:    character_color.txt
##
##  Detail:    reads .rgb file and prints out character vector of the color palette
##
##  Reference: <none>
##
##  Modifications:
##             --
##
###################################################################################################

# Open libraries/ packages
library(plotwidgets)
library(Jmisc)


# File name
fname = "../colors/MPL_hot"

# First line has number of colors in the palette information
clr_num <- read.csv(paste(fname,".rgb",sep=""), sep = "=", header = FALSE, nrows = 1)
clr_num <- clr_num[2]

# Skip first two lines and read all the colors
clr_rgb <- read.csv(paste(fname,".rgb",sep=""), skip = 2, sep = "", header = FALSE)

# Convert the color on transpose of the matrix (as rgb2col needs r-g-b as rows)
if (is.integer(clr_rgb[1])) {
  clr_pal <- clr_rgb/ 255
}else{
  clr_pal <- clr_rgb
}
clr_pal <- cbind(clr_pal, 1) # added 4th column "aplha" to control the brightness
clr_pal <- matrix(unlist(clr_pal), ncol = 4, byrow = FALSE) 
clr_pal <- rgb(clr_pal)
# clr_pal <- RgbToCol(t(clr_pal))

# Dump the palette vector in to a file
    # length(clr_pal) <- prod(dim(matrix(clr_pal, ncol = 8)))
    # write.table(matrix(clr_pal, ncol = 8, byrow = TRUE), file = paste(fname,".pal",sep = ""), sep = ",",
    #             col.names = FALSE, row.names = FALSE)
write.table(t(clr_pal), file = paste(fname,".pal",sep = ""), sep = ",",
                  col.names = FALSE, row.names = FALSE)




