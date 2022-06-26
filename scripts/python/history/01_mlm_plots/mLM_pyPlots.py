#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Mon Oct 29 10:55:55 2018

@author: shresthp
"""

# Code for plotting graphs from mLM LAKE water balance output

import numpy as np
import matplotlib.pyplot as plt
import re
import datetime as dt
import matplotlib.font_manager
import matplotlib.dates as mdates
import matplotlib.ticker as ticker


#---------------
# INITIALIZE
#---------------
data = [] # initialize data variable
date = [] # initialize date variable

# headers for the plot variables
headers = ['precipitation',         'evaporation',              'percolation',          #  0,  1,  2
           'baseflow',              'environmental flow',       'hydropwer flow',       #  3,  4,  5  
           'watersupply flow',      'irrigation flow',          'spill',                #  6,  7,  8
           'lake inflow',           'lake outflow',             'lake GW',              #  9, 10, 11
           'lake volume',           'precipitation',            'evaporation',          # 12, 13, 14
           'percolation',           'baseflow',                 'environmental flow',   # 15, 16, 17   
           'hydropwer flow',        'watersupply flow',         'irrigation flow',      # 18, 19, 20  
           'spill',                 'lake inflow',              'lake outflow',         # 21, 22, 23
           'lake outflow (obs)',    'lake level',               'lake level (obs)',     # 24, 25, 26
           'lake area',             'lake volume',              'lake GW']              # 27, 28, 29

# yaxis labels 
ylabs   = ['precipitation, mcm',    'evaporation, mcm',         'percolation, mm',           #  0,  1,  2
           'baseflow, mm',          'environmental flow, mcm',  'hydropwer, mcm',            #  3,  4,  5  
           'watersupply, mcm',      'irrigation, mcm',          'spill, mcm',                #  6,  7,  8
           'inflow, mcm',           'outflow, mcm',             'lake GW, mm',               #  9, 10, 11
           'volume, mcm',           'precipitation, mm d-1',    'evaporation, mm d-1',          # 12, 13, 14
           'percolation, mm d-1',   'baseflow, mm d-1',         'environmental flow, m3 s-1',   # 15, 16, 17   
           'hydropwer flow, m3 s-1','watersupply flow, m3 s-1', 'irrigation flow, m3 s-1',      # 18, 19, 20  
           'spill, m3 s-1',         'inflow, m3 s-1',           'outflow, m3 s-1',          # 21, 22, 23
           'outflow (obs), m3 s-1', 'level, m',                 'level (obs), m',           # 24, 25, 26
           'area, sq.kms.',         'volume, mcm',              'lake GW, mcm']             # 27, 28, 29

# colors for the plot variables (in the same order)
colors  = ['lightseagreen',         'lightseagreen',        'lightseagreen',
           'lightseagreen',         'lightseagreen',        'lightseagreen',
           'lightseagreen',         'lightseagreen',        'lightseagreen',
           'lightseagreen',         'lightseagreen',        'lightseagreen',
           'lightseagreen']

# Multiplot setup
# Plot 1
order1 = [ 9,  0,  1, 
           2,  3, 11, 
           8,  4,  5,
          12,  6,  7,
          10]
nrows1 = 5; ncols1 = 3
# Plot 2
order2 = [25, 27, 28, 
          22, 23]
nrows2 = 2; ncols2 = 3


#mfont = {'fontname':'Arial Unicode'}


#---------------
# READ FILE
#---------------
fname = "/Users/shresthp/pallav/01_work/Python/mLM_pyPlots/daily_waterBalance_lake1.bal"

with open(fname, "r") as f:
    content = f.readlines() # all file info dumped to content
# indent removed i.e. file closed


#---------------
# PREPARE Data
#---------------
for value in content[4:]: # reads each row of content
                          # rows 0-3 are headers
    
    # strip each row of training spaces and split delimited by consecutive spaces " +"
    value = list(re.split(" +", value.strip()))
    
    # convert the dates to date object and append to date list
    date.append(dt.date(int(value[3]), int(value[2]), int(value[1]))) # Cols 1, 2, 3 are day, month, year
    
    # convert all data to float
    value = [ float(x) for x in value[4:] ] # Column 4 onwards is data
    
    # append data to data list
    data.append(value)

# conver the list to array
data = np.asarray(data)


#---------------
# PLOT Data
#---------------

# Locators for month and year ticks
years       = mdates.YearLocator()    # every year
months      = mdates.MonthLocator()  # every month
yearsFmt    = mdates.DateFormatter('%Y')


##### Plot 1: All volumes of water balance #####

for iPlot, iVar in enumerate(order1):

    fig = plt.subplot(nrows1, ncols1, iPlot+1) # nrow, ncols, and index that moves upper left to right)
    
    # Tick location and format
    fig.yaxis.set_major_locator(ticker.MaxNLocator(5))
    fig.xaxis.set_major_locator(years)
    fig.xaxis.set_major_formatter(yearsFmt)
    fig.xaxis.set_minor_locator(months)
    
    # Label setup
    plt.ylabel(ylabs[iVar])
    plt.ylim(np.min(data[:, iVar]), np.max(data[:, iVar]))
    
    # applying date tick labels to only bottom plots
    if (iPlot + ncols1) <= np.count_nonzero(order1):
        fig.set_xticklabels([])
        
    plt.fill_between(date, data[:, iVar], color=colors[iVar])

    # checking plot variables: Ones with only nodata, limit will be set
    if (np.count_nonzero(data[:, iVar]) == 0):
         plt.ylim(0,1)
    
    plt.title(headers[iVar])
    
plt.subplots_adjust(wspace = 0.2, hspace = 0.2)
plt.show()

###### Plot 2: Lake states and I/O flows #####
#    
#for iPlot, iVar in enumerate(order2):
#
#    fig = plt.subplot(nrows2, ncols2, iPlot+1) # nrow, ncols, and index that moves upper left to right)
#    
#    # Tick location and format
#    fig.yaxis.set_major_locator(ticker.MaxNLocator(5))
#    fig.xaxis.set_major_locator(years)
#    fig.xaxis.set_major_formatter(yearsFmt)
#    fig.xaxis.set_minor_locator(months)
#    
#    # Label setup
#    plt.ylabel(ylabs[iVar])
#    plt.ylim(np.min(data[:, iVar]), np.max(data[:, iVar]))
#
#    # applying date tick labels to only bottom plots
#    if (iPlot + ncols2) < np.count_nonzero(order2): 
#        fig.set_xticklabels([])
#        
#    plt.fill_between(date, data[:, iVar], color='lightseagreen')
#    plt.title(headers[iVar])
#    
#    plt.show()
    
##### Plot 3: Observations versus simulation #####

### Water level sub plot
#fig = plt.subplot(1, 2, 1) # nrow, ncols, and index that moves upper left to right)
#
## Tick location and format
#fig.yaxis.set_major_locator(ticker.MaxNLocator(5))
#fig.xaxis.set_major_locator(years)
#fig.xaxis.set_major_formatter(yearsFmt)
#fig.xaxis.set_minor_locator(months)
#
## Label setup
#plt.ylabel("water level, m")
#    
## Plot
#plt.plot(date, data[:, 25], label='mHM', color='lightseagreen')
#plt.plot(date, data[:, 26], label='observed', color='black')
#plt.title("Water level comparison")
#plt.legend(loc='bottom right')
#
### Lake outflow sub plot
#fig = plt.subplot(1, 2, 2) # nrow, ncols, and index that moves upper left to right)
#
## Tick location and format
#fig.yaxis.set_major_locator(ticker.MaxNLocator(5))
#fig.xaxis.set_major_locator(years)
#fig.xaxis.set_major_formatter(yearsFmt)
#fig.xaxis.set_minor_locator(months)
#
## Label setup
#plt.ylabel("outflow, m3 s-1")
#    
## Plot
#plt.plot(date, data[:, 23], label='mHM', color='lightseagreen')
#plt.plot(date, data[:, 24], label='observed', color='black')
#plt.title("Lake outflow comparison")
#
#plt.legend(loc='upper left')
#
#plt.subplots_adjust(wspace = 0.2, hspace = 0.2)
#plt.show()





