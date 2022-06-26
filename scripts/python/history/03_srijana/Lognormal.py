#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Tue Aug 28 14:04:39 2018

@author: shresthp
"""

import scipy as sp
import numpy as np
import matplotlib.pyplot as plt


x = [0.73, 1.54, 0.8, 0.76, 0.67, 1.05, 1.72, 1.48, 0.61, 0.5, 0.9,
     1.69, 1.0, 1.26, 0.8, 1.61, 1.28, 0.93, 1.2, 1.18, 1.31, 1.3, 0.56, 
     1.1, 1.51, 0.8, 1.19, 1.64, 1.52, 0.7, 0.93, 0.92, 1.01, 1.69, 0.7, 
     0.89, 1.52, 0.62, 0.84, 1.2, 0.7, 1.47, 1.43]


x = np.sort(x)
sd = np.std(x)
mn = np.mean(x)

x1 = sp.log(x)
x1 = np.sort(x1)
sd1 = np.std(x1)
mn1 = np.mean(x1)

cdf = sp.stats.norm.cdf(x, mn, sd)
cdf1 = sp.stats.norm.cdf(x1, mn1, sd1)

plt.plot(x, cdf, "b--") # normal distribution fit
plt.plot(x1, cdf1, "red")# lognormal distribution fit