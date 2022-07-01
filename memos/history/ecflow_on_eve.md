# ecflow setup and usage on EVE


## **A. SETUP**
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


1. Load modules
`module load Anaconda3`
`source activate /global/apps/ecfPy/5.7.0`


2. Define the ECF port and host
`export ECF_PORT=<port> `
`export ECF_HOST=datascience1`
Each user should have a unique *ECF_PORT*. Enter your port [here](https://git.ufz.de/chs/ecfpy/-/wikis/home)

3. Make the ecflow server folder
`mkdir -p ~/ecflow_server/v5.7.0`

4. Start the server from this folder
log files will be written here
`cd ~/ecflow_server/v5.7.0`
`ecflow_server &`



## **B. Normal procedure**

1. activate
`module load Anaconda3`
`source activate /global/apps/ecfPy/5.7.0`

2. Define the ECF port and host
`export ECF_PORT=<port> `
`export ECF_HOST=datascience1`

3. Ping the server (optional, if you want to check)
`ecflow_client --ping`

4. Open the UI
`ecflow_ui &`


## **C. To Restart server**
Useful if your ecflow server is ping fails (e.g. due to EVE maintenance, etc.) 

1. activate
`module load Anaconda3`
`source activate /global/apps/ecfPy/5.7.0`

2. Define the ECF port and host
`export ECF_PORT=<port> `
`export ECF_HOST=datascience1`

3. Start the server from the ecflow server folder
`cd ~/ecflow_server/v5.7.0`
`ecflow_server &`

4. Ping the server
`ecflow_client --ping`

5. Open the UI
`ecflow_ui &`


## **D. Enhanced ecflow_ui with Portforwarding**

1. Install conda, and create ecflow environment in your local machine

2. Then open ecflow_ui and add a server with host as `localhost` and port as same as used for ecflow server on eve

3. Then use the following to start portforwarding between local machine and eve:
ssh -vJ <username>@datascience1.eve.ufz.de <username>@datascience1 -C -N -L <port>:datascience1:<port>

4. If you get `Address already in use` message:
- type the following:
`sudo lsof -i :<port>`
- note the PID from the table displayed and kill that PID:
`kill -9 <PID>`

5. Open the UI
`ecflow_ui &`




### **E. To Kill ecFlow server**

1. check with
`eclow_client --stats`

2. identify your victim (the process ID!) with 
`netstat -lnptu | grep ecflow`

3. then kill that process ID
`kill -9 <PID>`

4. confirm your kill with
`eclow_client --stats`





