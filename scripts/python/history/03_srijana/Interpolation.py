# -*- coding: utf-8 -*-
"""
Spyder Editor

This is a temporary script file.
"""
# With love from Pallu

# Libraries loaded
import scipy.interpolate as spi  # This is for interpolation
import matplotlib.pyplot as plt  # This is for plotting the graph
import numpy as np               # This is for creating equally spaced x_new

# Dummy data for demonstration
#   - This should be your exp data
x = [1, 2.5, 3.4, 5.8, 6]
y = [2, 4, 5.8, 4.3, 4]

slices = 5  # Number of slices of intervals for x_new and y_new

x_new = np.linspace(1, 6, slices) # Equally spaced new x 
                                  #  (start, end, intervals)
                                  
y_new = []                        # Defining new y as a list  

func_interp = spi.interp1d(x, y)  # function for interpolation
                                  # I think this one is linear interpolation i.e.
                                  # straignt line between two points

for i in range(slices):           # i becomes [0, 1, 2, ... slices]. Yes,
                                  # the index always starts from 0 in python
                                  # i.e. first element of x_new is x_new[0]
                                  
    y_new.append (func_interp(x_new[i]))  # Calling function for a value of 
                                          # new x and storing in new y  
                                          
# Visualizations
plt.plot(x, y, "red")         # Old plot
plt.plot(x_new, y_new, "b--") # New plot