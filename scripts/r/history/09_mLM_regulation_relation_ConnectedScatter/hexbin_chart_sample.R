# Library
library(tidyverse)

# Data
a <- data.frame( x=rnorm(20000, 10, 1.9), y=rnorm(20000, 10, 1.2) )
b <- data.frame( x=rnorm(20000, 14.5, 1.9), y=rnorm(20000, 14.5, 1.9) )
c <- data.frame( x=rnorm(20000, 9.5, 1.9), y=rnorm(20000, 15.5, 1.9) )
data <- rbind(a,b,c)


# Basic scatterplot
ggplot(data, aes(x=x, y=y) ) +
  geom_point()

# 2d histogram with default option
ggplot(data, aes(x=x, y=y) ) +
  geom_hex() +
  theme_bw()