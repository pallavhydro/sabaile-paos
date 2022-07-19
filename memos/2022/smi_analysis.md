# Memos on SMI analysis


## SMI map to driest and wettest year based on precipitation

mHM input pre.nc can be used to get the driest and wettest year. However, the pre.nc is usually not masked out for the domain of interest. In order to do that, *run mHM at L2 resolution*. The netcdf output from mHM can then be used to create a mask at L2. Then the mask can be used to mask out pre.nc for the modelled domain. 

1. Generate L2 domain mask

```
cdo selvar,<a variable in the mHM netcdf output> -seltimestep,1 <mhm netcdf output> mhm_output_temp1.nc

cdo div mhm_output_temp1.nc mhm_output_temp1.nc mask.nc
```
This creates a netcdf of single time slice, consisting of `1` all over the domain and `nodata` outside of the domain.
\

2. Mask out pre.nc

```
cdo mul mask.nc pre.nc pre_masked.nc
```
\

3. Find driest and wettest years from precipitation

```
cdo selyear,<sstart YYYY/end YYYY> pre_masked.nc pre_masked_YYYY_YYYY.nc

cdo yearsum pre_masked_YYYY_YYYY.nc pre_masked_YYYY_YYYY_yearsum.nc

cdo fldmean pre_masked_YYYY_YYYY_yearsum.nc pre_masked_YYYY_YYYY_fldmean.nc

cdo infon pre_masked_YYYY_YYYY_fldmean.nc

```
The cdo infon can be used to check the values and determine the driest and wettest years.
\

4. SMI of the driest and wettest year

```
cdo selyear,<driest or wettest YYYY> SMI.nc SMI_YYYY.nc

ncview SMI_YYYY.nc &

```

It would make sense to the reader if the SMI maps of 12 months of the dry and wet years are placed in a single multiplot (e.g. 6x4 matrix) with month as titles and with same SMI color map (e.g. 0 to 1, or SMI class colors)


\

