#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed Jan 30 11:16:00 2019

@author: shresthp
"""

# Code for plotting graphs from mHM optimization (ddsresults.out)

import numpy as np
import matplotlib.pyplot as plt
import re
import datetime as dt
import matplotlib.dates as mdates
import matplotlib.ticker as ticker
import pandas as pd



#---------------
# INITIALIZE
#---------------

optdata = []
headers = []




#---------------
# READ FILE
#---------------

foptdata = "/Users/shresthp/pallav/01_work/Python/mLM_pyPlots/11_IsoOptimization_I/dds_results_monthlyReg.out"

with open(foptdata, "r") as f:
    content_optdata = f.readlines() # all file info dumped to content

for value in content_optdata[7:]: # reads each row of content
                          # rows 0-7 are headers
    
    # strip each row of trailing spaces and split delimited by tabs /t
    value = list(re.split(" +", value.strip()))
    
    # append data to data list
    optdata.append(value[:]) # Column 5 is data
    
# convert the list to array
optdata = np.asarray(optdata)

# convert to numeric
optdata = optdata.astype(np.float)



#---------------
# PLOT DATA
#---------------

headers = ['top_of_inactive_pool', 'top_of_conservation_pool', 'top_of_flood_control_pool',
                   'inflow_flood_threshold', 'dsControl_point_flood_threshold', 'longterm_baseflow_feed',
                   'exponent_for_percolation']

xlabs = ['masl', 'masl', 'masl',
                   'm3.s-1', 'm3.s-1', 'mm.TS-1',
                   '--']

# Multiplot setup
# Plot 1
order1 = [ 58, 59, 60, 
          61, 62, 63, 
          64]
nrows1 = 3; ncols1 = 3

##### Plot 1: Parameter Sensitivity #####

for iPlot, iVar in enumerate(order1):

    fig = plt.subplot(nrows1, ncols1, iPlot+1) # nrow, ncols, and index that moves upper left to right)
    
    # Tick location and format
    fig.yaxis.set_major_locator(ticker.MaxNLocator(5))
    
    # Label setup
    plt.xlabel(xlabs[iVar - order1[0]])
    plt.ylabel("1-KGE")

    # Axis limits
    plt.ylim(np.min([optdata[:, 1]]), np.max([optdata[:, 1]])) # Second column is objective function value
    
        
    #===== Plot command ======#
    plt.scatter(optdata[:, iVar], optdata[:, 1])
    
    
    plt.title(headers[iVar - order1[0]])
    plt.legend(loc='upper left')
    
plt.subplots_adjust(wspace = 0.5, hspace = 0.5)
plt.show()

    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    