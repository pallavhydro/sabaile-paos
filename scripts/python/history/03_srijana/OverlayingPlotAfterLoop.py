#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Mon Aug 27 07:57:33 2018

@author: shresthp
"""

import matplotlib.pyplot as plt


x = [1, 2, 3, 4, 5]
y1 = [1, 2, 3, 4, 5]
y2 = [2, 3, 4, 5, 6]


for i in range(2):
    plt.plot(x, y1)

plt.plot(x, y2)
plt.show()