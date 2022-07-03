# ECMWF forecast issuance



## **Normal** procedure

0. Access ecmwf server and pull the ecfpy git from remote for updates. One needs to do this from *ecgate*.

1. Edit `suite_ulysses_seasonal_forecast.py` from ecgate. Then from ccb, *module load python3* and run the code with *./suite_ulysses_seasonal_forecast.py* 4x - three restart runs (1x ERA5L, 2x ERA5t - as ERA5L has a latency of 2 months) and one forecast run. When prompted for `load to server?` type yes/y.

2. *ERA5land* availability (for m = 1): Latency of *2 months*. Check out the availability (**end day** of the latest month) via ![this link](https://apps.ecmwf.int/mars-catalogue/?levtype=sfc&month=jan&year=2021&type=fc&expver=1&stream=oper&class=l5)

3. *ERA5t* availability (only for m = 3): Latency of *2 days*. Check out the availability (**end day** of the latest month) via ![this link](https://apps.ecmwf.int/mars-catalogue/?levtype=sfc&month=jan&year=2021&type=fc&expver=5&stream=oper&class=ea)

4. *SEAS5* availability: Latency of *2 days*. Check out the availability (**end day** of the latest month) via ![this link](https://apps.ecmwf.int/mars-catalogue/?origin=ecmf&stream=mmsf&levtype=sfc&time=00%3A00%3A00&system=5&expver=1&month=apr&method=1&year=2021&date=2021-04-01&type=fc&class=od)






### **Tweaks** for Normal procedure

1. *solved* `Adjust_forcing`: At the moment the MPI enabled executable of adjust_forcing is having some MPI related issues. This mainly happens for ERA5t and not a problem for ERA5Land or the forecasts. This needs to be manually run using non-MPI executable (*/perm/mo/nest/ulysses/src/adjust_forcing/build_intel_era5t/adjust_forcing*), takes about 90 mins. Make sure to run *prgenvswitchto intel* and load *netcdf4* prior to the execution.

2. Restart files after the ERA5L runs need to be manually copied from *ulysses/data/restart_files/<hm>/yyyymm* to where ERA5t run looks for restart files i.e. *ulysses/data/restart_files/`era5t`/<hm>/yyyymm*. This needs to be done in ST's scratch at */scratch/mo/nest/ulysses/data/restart_files/*. This is only required for the first ERA5t month.

3. `qc_` (comparison check task) for forecast is not needed. Set all `qc_` as completed.

4. Htessel might fail with *The program was unable to request more memory space* message. In that case, increase *MEMPERTASK* to 120 G.

5. If the restart files from scratch have been lost in clean up, copy the required files from *ECFS*. Easy way to do that is using the script *archive_static_data.sh* from the **pre_proc** repository, with `retrieve = 1` and source, target directories and folders edits as required.

6. The pointers to restart files (read/ write) are hard coded to */scratch/mo/nest/ulysses/data/restart_files/*. If one needs to work in one's own scratch and work with restart files there, the following needs to be done -
	1. `update_restart write restart` - change the variable `tgt_dir` in *ecflow_home/<corresponding_folder>/files/copy_restart.ecf*. This changes the write restart for all HMs and mRMs.
	2. `update_restart read restart` - change the path to restart file variable from the ecflow_ui at *hm_run* and *mrm_hm* family levels.
	3. `forecast read restart` - change line *101* in *setup/setup_paths.py* to change *self.restartdir* to */scratch/ms/copext/cypk/ulysses/data/restart_files/* (re-)submit the suite.

7. There are some directories for `ERA5t` (or `ERA5L`??) that exist and should be deleted manually as the restart runs would not be able to overwrite the folders and stops with error. 

8. Supend all the `mars_upload` tasks (1x meteo + 4x models). Once data is uploaded to MARS, its set and done. Thus, we push only once everything is checked and confirmed. 

9. If Jules fails in sanity_check for surface temperature, change *JULES_JULES_TIME_TIMESTEP_LEN* (default 3600, change 1800), *WALLTIME* for jules_post (default 6 hrs, change 12 hrs), *WALLTIME* for Jules' sanity_check (default 2 hrs, change 4 hrs). And then *requeue*.




### Restarting **ecflow server** 

If `ecflow_client --ping` says the server is not active, go through the following steps -

1. Login to ccb. `module load ecflow/5`. Export `ECF_PORT` and `ECF_HOST`. 
2. `ecflow_start.sh -d <path>` where path needs to be in absolute path to `ecserver_log` folder.
3. Confirm the server being active using `ecflow_client --ping`.





### **ECFS** - ECMWF's File Storage system

1. Load the ecfs module from either *ecgate* or *ccb*
`module load ecfs`

2. Access using selected CL syntaxes as listed in the ![ECWMF's confluence webpage](https://confluence.ecmwf.int/display/UDOC/ECFS). For an instance:
`els -l ec:/nest/ulysses/cds_upload/2020`




### **Scratch Storage limit** - ECMWF's scratch

1. The space limit on sractch (for me) is around 17-20 TB. Each monthly forecast run is around 8 TB. Thus, in order to make more forecast runs, I need to delete completed forecast run. I do that by deleting the forecast folder from ecflow_work. Of course, the data needs to be backed up at ECFS and uploaded to MARS.  
`rm -rf up_forecastYYYY_MM_12`

2. The ecflow_home forecast folder is left for self-deletion in next two weeks by the system.




### **Scratch and Touch** - ECMWF's scratch

1. The scratch on ECMWF server cleans itself of files unused for two weeks. In order to prevent file loss (mainly the *data*), one can touch all files within */scratch/ms/copext/cypk/ulysses/data/* on a weekly basis.

2. The one-liner for such touch task would be - `find . -type f -exec touch {} +`. Side note: one can opt for touching only selected files (e.g. txts) using `find . -type f -name "*.txt" -exec touch {} +`. Matthias even suggests `find . -exec touch {} \;` and `find . -user nemk -exec touch {} \;`.




## Hints

1. The `stream` variable in `suite_ulysses_seasonal_forecast.py` represents forcings during the restart/ update runs i.e. can be ERA5L or ERA5t. While in forecast run it represents restart point/ run to initialize from i.e. should be ERA5t.

2. Refer to ![this document](https://git.ufz.de/ulysses/management/-/blob/master/run_forecast_suite.pdf) in ULYSSES/Management git project for step-by-step guide to run forecast with the ecflow suite.

3. Out of the two ecmwf servers, ccb is more available than cca.

4. Although commands are pushed from ccb, editing using the ecmwf forntend `ecgate` is preferred. `\hpc\` is the prefix to reach ccb from ecgate. This works for *perm* but not *scratch*!

5. In ecflow, `ctrl + s` = suspend and `ctrl + r` = resume.

6. Whenever there are issues, go to the `output` tab of ecflowUI. 

7. When one needs to make conditional selections of family/ tasks, go to `query` option of ecflowUI. 

8. Use `qstat -u "cypl"` as in EVE to check the submitted jobs

9. Open files using emacs. Emacs is a bit faster in egcate than ccb. Type `emacs -nw yourfile`, where -nw prevents a new window and allows for terminal based editing.

10. To save in emacs type `ctrl+x` and `ctrl+s`. To close emacs, type `ctrl+x` and `ctrl+c`. To seach in emacs, type `ctrl+s` and type the search phrase. To exit from seach mode, press any `arrow key`. To find a file in the current path, type `ctrl+f` and search for file name.

11. To place a running program (e.g. ecflow_ui) to background, type `ctrl+z` and then type `bg` enter. 

12. One can check the status of ecmwf servers/ services (e.g. whether ccb is up or not) via ![this link](https://www.ecmwf.int/en/service-status)

13. If `variables need to be edited`, that can be done directly from the UI. Its most efficient to edit the variable from the source level, than doing individually at task level. 

14. If `hard code need to be edited`, that can be done by editing the ecf files in *ecflow_home/<corresponding_folder>/files*.

15. To upload to next cloud use `curl -u username:password -T path/to/file/in/local/file.txt "https://nc.ufz.de/remote.php/dav/files/username/path/to/file/in/ncloud/file.txt"`





## Sample issues (June issue)

1. **Some unit issue** for meteorological output - this has been ratified in the code and is not expected to occur in future. 

2. **Random absence of files/ folders** Some file/ folders are not generated by the suite and the tasks crash. These files/ folders need to be copied manually to where they are missing.

3. **Server (ccb) crashes/ restarts** use (from ccb) `ecflow_client --ping` to check whether your ecflow server is still running. If not, restart server with `ecflow_start.sh -d $PERM/ecserver_log`. Now reload the ecflow UI from ecgate.






## Requirements

1. Access to ecmwf server system via a Jira request/ ticket.

2. `ssh key` setup for bitbucket on cca or ccb depending on the one you are using. ![How to create ssh key](https://confluence.atlassian.com/bitbucketserver/creating-ssh-keys-776639788.html)

3. Access to `git.ecmwf.int`. Should be automatic once user is part of `c3s432l3_projacct`




## Direct Data links

1. ![ERA5Land](
https://apps.ecmwf.int/mars-catalogue/?stream=oper&levtype=sfc&expver=1&month=jan&year=2021&type=fc&class=l5)

2. ![ERA5T](
https://apps.ecmwf.int/mars-catalogue/?class=ea&stream=oper&expver=5&type=fc&year=2021&month=apr&levtype=sfc)

3. ![Operational forecasts](
https://apps.ecmwf.int/mars-catalogue/?origin=ecmf&stream=mmsf&levtype=sfc&time=00%3A00%3A00&system=5&expver=1&month=apr&method=1&year=2021&date=2021-04-01&type=fc&class=od)



## Folder structure in ecmwf server

# Scratch - *ulysses/data* folder

- `data` - all restart files

# Scratch - *ulysses/ecflow operations* folder

scratch ecflow operational folder -

- `ecflow_home` - all the scripts (.ecf, includes, ...)
- `ecflow_work` - all the data

home and work -

- `up_update_restartyyyy_mm_12`
OR 
- `up_forecastyyyy_mm_12` where `up` stands for ulysses projet and `12` is the target DOM we want to get the forecasts ready. 

home/yyyy_mm_12 -

- `files` - ecflow (.ecf) files 
- `incld` - include files/ namelists sections with place holders (% %) 
- `init/data` and `init/progs` - job files for initialiazation (.1, .job0, .job1) 
- `update_restart` or `forecast` - member folders (`mx`) with job files for programs (.1, .job0, .job1) 

home/yyyy_mm_12/update_restart/mx or home/yyyy_mm_12/forecast/mx contains *job* files for the following -

- `adjust_forcing`
- `htessel`
- `jules`
- `mars_download`
- `mhm`
- `mrm`
- `pgb`

work/yyyy_mm_12 -

- `data` 
	- *constant input* data (soft links)
- `progs` 
	- all *executables*
- `update_restart`/ `forecast` 
	- *variable input* data (e.g. meteo)
	- *restarts* (soft links)
	- *output* data
	- *namelist* files
	- *runtime output* files

work/yyyy_mm_12/update_restart/mx or work/yyyy_mm_12/forecast/mx -

- `adjust_forcing`
- `download`
- `ecmwf` - final dataset for 4 models
- `htessel`
- `jules`
- `mhm`
- `mrm`
- `pgb`


# Perm

Perm folder structure -

- `ecflow_log` - (empty)
- `ecfpy` - ecflow python ufz git repository
- `ecserver_log` - ecflow server log files (to be used while *restarting* your ecflow server). *ecflow UI* uses these log files to resume.
- `git` - other git repositories
	- `ulysses` - ecmwf's bitbucket repository, a *mirror* of ulysses/preproc
	- `adjust_forcings` - ufz's git repository of ulysses/adjust_forcings





