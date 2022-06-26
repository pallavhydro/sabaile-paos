####################################################

#  Program to fit function over the Grishchenko 
#  Water Albedo dataset to replace Fresnel's equation

#  Pallav Kumar Shrestha, March 2022

# Reference: https://stackoverflow.com/questions/33112947/fitting-a-curve-to-weibull-distribution-in-r-using-nls

####################################################

library(nls2)



## == Prepare Parameter combinations

pars <- expand.grid(k=seq(0.1, 10, len=10),
                    l=seq(0.1, 10, len=10),
                    c= 4, # An intercept
                    s=seq(1, 100, len=10)) # A scalar multiplier to scale the curve (y)


## == Setup Data

# y <- c(30, 37.75, 24.5, 18.75, 14, 9, 7, 6, 5, 4.5, 4, 4, 4, 4)
y <- c(30, 37.75, 27, 18, 12.5, 9, 6.7, 5.5, 5, 4.5, 4, 4, 4, 4) # Modified/ smoothened
x <- c(2.5 , 7.5 , 12.5, 17.5, 22.5, 27.5, 32.5, 37.5, 42.5, 47.5, 52.5, 57.5, 62.5, 67.5)
x <- x/10 # x transformation 

# Put the data in a data.frame
dat <- data.frame(x=x, y=y)



## == Fit Weibull function on Grishchenko dataset

# brute-force data to get improve parameter estimate
res <- nls2(y ~ s*((k/l) * ((x/l)^(k-1)) * exp(- (x/l)^k)) + c, data=dat,
            start=pars, algorithm='brute-force')

# Use the improved parameter estimate with nls
res1 <- nls(y ~ s*((k/l) * ((x/l)^(k-1)) * exp(- (x/l)^k)) + c, data=dat,
            start=as.list(coef(res)))



## == Plot
plot(dat, col="steelblue", pch=16, xlab = "Solar inclination (degrees) x 10-1", ylab = "Water albedo (%)")
points(dat$x, predict(res), col="salmon", type="l", lwd=2) # First estimate
points(dat$x, predict(res1), col="black", type="l", lwd=2) # Final estimate


