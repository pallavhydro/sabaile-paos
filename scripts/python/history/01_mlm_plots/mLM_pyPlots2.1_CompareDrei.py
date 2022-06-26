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
import matplotlib.dates as mdates
import matplotlib.ticker as ticker
import pandas as pd

#---------------
# INITIALIZE
#---------------

dataLevel = [] # initialize data variable
dateLevel = [] # initialize date variable
dataOutflow = [] 
dateOutflow = [] 
dataSpill = [] 
dateSpill = [] 
data1 = [] 
date1 = [] 
data2 = [] 
date2 = [] 

# headers for the plot variables
headers = ['precipitation',         'evaporation',              'percolation',          #  0,  1,  2
           'baseflow',              'environmental flow',       'hydropwer flow',       #  3,  4,  5  
           'watersupply flow',      'irrigation flow',          'spill',                #  6,  7,  8
           'lake inflow',           'lake outflow',             'lake GW',              #  9, 10, 11
           'lake volume',           'precipitation',            'evaporation',          # 12, 13, 14
           'percolation',           'baseflow',                 'environmental flow',   # 15, 16, 17   
           'hydropwer flow',        'watersupply flow',         'irrigation flow',      # 18, 19, 20  
           'spill',                 'lake inflow',              'lake outflow',         # 21, 22, 23
           'lake level',            'lake area',                'lake volume',          # 24, 25, 26
           'lake GW']                                                                   # 27

# yaxis labels 
ylabs   = ['precipitation, mcm',    'evaporation, mcm',         'percolation, mm',           #  0,  1,  2
           'baseflow, mm',          'environmental flow, mcm',  'hydropwer, mcm',            #  3,  4,  5  
           'watersupply, mcm',      'irrigation, mcm',          'spill, mcm',                #  6,  7,  8
           'inflow, mcm',           'outflow, mcm',             'lake GW, mm',               #  9, 10, 11
           'volume, mcm',           'precipitation, mm d-1',    'evaporation, mm d-1',          # 12, 13, 14
           'percolation, mm d-1',   'baseflow, mm d-1',         'environmental flow, m3 s-1',   # 15, 16, 17   
           'hydropwer flow, m3 s-1','watersupply flow, m3 s-1', 'irrigation flow, m3 s-1',      # 18, 19, 20  
           'spill, m3 s-1',         'inflow, m3 s-1',           'outflow, m3 s-1',          # 21, 22, 23
           'level, m',              'area, sq.kms.',            'volume, mcm',              # 24, 25, 26
           'lake GW, mcm']                                                                  # 27


# Multiplot setup
# Plot 1
order1 = [ 9,  0, 26, 
           5,  1,  2, 
          21, 25, 11,
          23, 24, 16]
nrows1 = 4; ncols1 = 3


#mfont = {'fontname':'Arial Unicode'}


#---------------
# READ FILE
#---------------
# Lake level
flevel = "/Users/shresthp/pallav/01_work/Python/mLM_pyPlots/Observations/1.lvl"
# Lake outflow
foutflow = "/Users/shresthp/pallav/01_work/Python/mLM_pyPlots/Observations/41020002_SAR.txt" 
# Lake spill
fspill = "/Users/shresthp/pallav/01_work/Python/mLM_pyPlots/Observations/1.spl"
# Output 1
fname1 = "/Users/shresthp/pallav/01_work/Python/mLM_pyPlots/09_Introducing_SeasonalPoolLevels/daily_waterBalance_lake1_008_seasonalPoolLevelsTest.bal"
# Output 2
fname2 = "/Users/shresthp/pallav/01_work/Python/mLM_pyPlots/09_Introducing_SeasonalPoolLevels/daily_waterBalance_lake1_008_seasonalPoolLevelsTest.bal"


with open(flevel, "r") as f:
    contentLevel = f.readlines() # all file info dumped to content
with open(foutflow, "r") as f:
    contentOutflow = f.readlines() # all file info dumped to content
with open(fspill, "r") as f:
    contentSpill = f.readlines() # all file info dumped to content
with open(fname1, "r") as f:
    content1 = f.readlines() # all file info dumped to content
with open(fname2, "r") as f:
    content2 = f.readlines() # all file info dumped to content
# indent removed i.e. file closed


#------------------------------
# PREPARE Data - Observations
#------------------------------
# Data Level
for value in contentLevel[5:]: # reads each row of content
                          # rows 0-5 are headers
    
    # strip each row of trailing spaces and split delimited by tabs /t
    value = list(re.split("\t", value.strip()))
    
    # convert the dates to date object and append to date list
    dateLevel.append(dt.date(int(value[0]), int(value[1]), int(value[2]))) # Cols 1, 2, 3 are year, month, day
    
    # append data to data list
    dataLevel.append(value[5]) # Column 5 is data

# convert the list to array
dataLevel = np.asarray(dataLevel)
# convert the date and data to pandas time series
index = pd.DatetimeIndex(dateLevel)
dataLevel = pd.Series(dataLevel, index=index)
# convert to numeric
dataLevel = pd.to_numeric(dataLevel)
# replace missing values by NaN
dataLevel = dataLevel.replace(-9999, np.nan)

# Data Outflow
for value in contentOutflow[5:]: # reads each row of content
                          # rows 0-5 are headers
    
    # strip each row of trailing spaces and split delimited by tabs /t
    value = list(re.split("\t", value.strip()))
    
    # convert the dates to date object and append to date list
    dateOutflow.append(dt.date(int(value[0]), int(value[1]), int(value[2]))) # Cols 1, 2, 3 are year, month, day
    
    # append data to data list
    dataOutflow.append(value[5]) # Column 5 is data

# convert the list to array
dataOutflow = np.asarray(dataOutflow)
# convert the date and data to pandas time series
index = pd.DatetimeIndex(dateOutflow)
dataOutflow = pd.Series(dataOutflow, index=index)
# convert to numeric
dataOutflow = pd.to_numeric(dataOutflow)
# replace missing values by NaN
dataOutflow = dataOutflow.replace(-9999, np.nan)

# Data Spill
for value in contentSpill[5:]: # reads each row of content
                          # rows 0-5 are headers
    
    # strip each row of trailing spaces and split delimited by tabs /t
    value = list(re.split("\t", value.strip()))
    
    # convert the dates to date object and append to date list
    dateSpill.append(dt.date(int(value[0]), int(value[1]), int(value[2]))) # Cols 1, 2, 3 are year, month, day
    
    # append data to data list
    dataSpill.append(value[5]) # Column 5 is data

# convert the list to array
dataSpill = np.asarray(dataSpill)
# convert the date and data to pandas time series
index = pd.DatetimeIndex(dateSpill)
dataSpill = pd.Series(dataSpill, index=index)
# convert to numeric
dataSpill = pd.to_numeric(dataSpill)
# replace missing values by NaN
dataSpill = dataSpill.replace(-9999, np.nan)

#------------------------------
# PREPARE Data - Simulations
#------------------------------
# Data 1
for value in content1[4:]: # reads each row of content
                          # rows 0-3 are headers
    
    # strip each row of training spaces and split delimited by consecutive spaces " +"
    value = list(re.split(" +", value.strip()))
    
    # convert the dates to date object and append to date list
    date1.append(dt.date(int(value[3]), int(value[2]), int(value[1]))) # Cols 1, 2, 3 are day, month, year
    
    # convert all data to float
    value = [ float(x) for x in value[4:] ] # Column 4 onwards is data
    
    # append data to data list
    data1.append(value)

# convert the list to array
data1 = np.asarray(data1)

# Data 2
for value in content2[4:]: # reads each row of content
                          # rows 0-3 are headers
    
    # strip each row of training spaces and split delimited by consecutive spaces " +"
    value = list(re.split(" +", value.strip()))
    
    # convert the dates to date object and append to date list
    date2.append(dt.date(int(value[3]), int(value[2]), int(value[1]))) # Cols 1, 2, 3 are day, month, year
    
    # convert all data to float
    value = [ float(x) for x in value[4:] ] # Column 4 onwards is data
    
    # append data to data list
    data2.append(value)
    
# convert the list to array
data2 = np.asarray(data2)

## Data 3
#for value in content3[4:]: # reads each row of content
#                          # rows 0-3 are headers
#    
#    # strip each row of training spaces and split delimited by consecutive spaces " +"
#    value = list(re.split(" +", value.strip()))
#    
#    # convert the dates to date object and append to date list
#    date3.append(dt.date(int(value[3]), int(value[2]), int(value[1]))) # Cols 1, 2, 3 are day, month, year
#    
#    # convert all data to float
#    value = [ float(x) for x in value[4:] ] # Column 4 onwards is data
#    
#    # append data to data list
#    data3.append(value)
#    
## convert the list to array
#data3 = np.asarray(data3)


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
#    plt.ylim(np.min([data1[:, iVar], data2[:, iVar]]), np.max([data1[:, iVar], data2[:, iVar]]))
    plt.ylim(np.min([data1[:, iVar]]), np.max([data1[:, iVar]]))
    
    # applying date tick labels to only bottom plots
    if (iPlot + ncols1) <= np.count_nonzero(order1):
        fig.set_xticklabels([])
        
    plt.fill_between(date1, data1[:, iVar], color="lightseagreen", label='Test Run', alpha = 0.5)
#    plt.fill_between(date2, data2[:, iVar], color="lightcoral", label='Seasonal Pool Levels', alpha = 0.5)
#    plt.fill_between(date3, data3[:, iVar], color="gray", label='no Hydropower no Spill', alpha = 0.5)
    
    # Inserting observations
    if (iVar == 21):
        plt.plot(date1, dataSpill[date1[0]:date1[-1]], label='observed', color='black', alpha = 0.7)
    if (iVar == 23):
        plt.plot(date1, dataOutflow[date1[0]:date1[-1]], label='observed', color='black', alpha = 0.7)
    if (iVar == 24):
        plt.plot(date1, dataLevel[date1[0]:date1[-1]], label='observed', color='black', alpha = 0.7)
        
    # checking plot variables: Ones with only nodata, limit will be set
    if (np.count_nonzero(data1[:, iVar]) == 0):
         plt.ylim(0,1)
    
    plt.title(headers[iVar])
    plt.legend(loc='upper left')
    
plt.subplots_adjust(wspace = 0.2, hspace = 0.2)
plt.show()







