# Memos of Portforwarding on ECMWF server 
(including contributions from Robert Schweppe)


## Steps

1. Follow the installation of tsh as described [here up](https://confluence.ecmwf.int/display/UDOC/Teleport+SSH+Access) until "Configuring password-less login", rest is not needed.

2. Start a server and a suite on the ecmwf server

3. Then do everything after 2.2. [here](https://confluence.ecmwf.int/display/ECFLOW/Teleport+-+using+local+ecflow_ui#Teleportusinglocalecflow_ui-Method%232:DynamicPortForwarding). 

- For Atos
`ssh -v -C -N -D 9050 -J <username>@jump.ecmwf.int <username>@aa-login`
- FOR ECMWF-Reading
`ssh -v -C -N -D 9050 -J <username>@shell.ecmwf.int <username>@ccb-login4`

4. The proxychains worked via 
`brew install proxychains-ng` 
ie didn't have to compile from source. 
OR 
do it from source with 
`./configure && make && sudo make install-config`)

5. Finally run the following then add the server, done.
`ecflow_ui -cmd proxychains4` 