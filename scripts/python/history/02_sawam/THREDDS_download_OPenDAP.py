#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed Feb 20 16:21:14 2019

@author: shresthp
"""

import xarray as xr
import requests

# Approach 0

from pydap.client import open_url

url = "https://SaWaM:SaWaM_User_2018@thredds.imk-ifu.kit.edu:9670/thredds/dodsC/ERA5/prec/daily/0.1/WC2"

ds1 = open_url(url)



# Approach I
session = requests.Session()
session.auth = ('SaWaM', 'SaWaM_User_2018')

store = xr.backends.PydapDataStore.open("""https://thredds.imk-ifu.kit.edu:9670/
                                        thredds/dodsC/ERA5/prec/daily/0.1/WC2?""",
#                                        lon[0:1310:1450],
#                                        lat[0:675:875],time[0:1:6574],
#                                        prec[0:1:6574][0:675:875][0:1310:1450]""",
                                        session=session)
ds = xr.open_dataset(store)


# Approach II
ds = xr.open_dataset("""https://SaWaM.SaWaM_User_2018@thredds.imk-ifu.kit.edu:9670/
                     thredds/dodsC/ERA5/prec/daily/0.1/WC2""")


# Sample example: http://xarray.pydata.org/en/stable/io.html#opendap

remote_data = xr.open_dataset('http://iridl.ldeo.columbia.edu/SOURCES/.OSU/.PRISM/.monthly/dods', decode_times=False)
tmax = remote_data['tmax'][:500, ::3, ::3]
tmax[0].plot()