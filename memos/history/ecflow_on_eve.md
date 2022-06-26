ecflow setup and usage on EVE


### **A. SETUP** - *begin*
Setup is a one time thingy 

<!-- Old:
# Load conda
`module load Anaconda3/2020.07`

# create the conda env
`conda create -c conda-forge --name ecflow_env python=3.8.6`
By default, conda environments are stored in `~/.conda/envs/`

# activate
# `conda activate ecflow_env`

# install the dependencies
`conda install -c conda-forge f90nml sh ecflow` -->


New: (eve's ecflow)
`module load Anaconda3`
`source activate /global/apps/ecfPy/5.7.0`


# Define the ECF port and host
`export ECF_PORT=43999 `
`export ECF_HOST=datascience1`
Each user should have a unique *ECF_PORT*

# Make the ecflow server folder
`mkdir -p ~/ecflow_server/v5.7.0`

# Start the server from this folder
log files will be written here
`cd ~/ecflow_server/v5.7.0`
`ecflow_server &`

### **Setup** - *end*



### **B. Normal procedure**

# activate
`module load Anaconda3`
`source activate /global/apps/ecfPy/5.7.0`

# Define the ECF port and host
`export ECF_PORT=43999 `
`export ECF_HOST=datascience1`

# Ping the server (optional, if you want to check)
`ecflow_client --ping`

# Open the UI
`ecflow_ui &`


### **C. To Restart server**
Useful if your ecflow server is ping fails (e.g. due to EVE maintenance, etc.) 

# activate
`module load Anaconda3`
`source activate /global/apps/ecfPy/5.7.0`

# Define the ECF port and host
`export ECF_PORT=43999 `
`export ECF_HOST=datascience1`

# Start the server from the ecflow server folder
`cd ~/ecflow_server/v5.7.0`
`ecflow_server &`

# Ping the server
`ecflow_client --ping`

# Open the UI
`ecflow_ui &`


### **D. Enhanced ecflow_ui with Portforwarding**

ssh -vJ shresthp@datascience1.eve.ufz.de shresthap@datascience1 -C -N -L 43999:datascience1:43999




