# Memos on useful tricks and workarounds on Bash


1. Store number of lines in a file to a variable

```
	npoints=`wc -l < test.txt`

```
\

2. Round up (or down) in bash (e.g. 100/3)

```
	number=$(( (100 + 3 - 1)/3 )) # adding (denominator - 1) helps to round up

```
\


3. For loop in bash

```
Option 1:
	for (( i = 0 ; i < ${max} ; i++ )) ; do # where i starts from 0 and ends at (max - 1)
		...
	done


Option 2:
	for i in {0..10..2}; do # where i starts from 0 and ends at 10
		...
	done


Option 3: if variable is to be used as loop control

	for i in $( seq 0 ${step} ${end} ); do # where i starts from 0 and ends at "end"
		...
	done

```
\


4. Check if a directory exits and make one (with parent folder structure) if not already

```
	if [ ! -d ${mydir} ]; then
	    mkdir -p ${mydir}
	fi

```
\

5. Copy lines from a file to another file (e.g. lines 16 to 80)

```
head -80 file | tail -16 > newfile
```
\

6. If statement in bash

```
Options 1: with numeric expression

if [[ ${a} < ${b} ]]; then 
	echo "works"
fi
```
\

7. Control tmux panes with mouse

Add the following to `~/.tmux.conf`

```
set -g mouse on

```

Then source the config file


```
tmux source-file ~/.tmux.conf
```
\

8. Create a conda env at default folder with a name

```
conda create --name mhm_env
```
\

9. X11 forwarding (source: https://unix.stackexchange.com/a/12772)

X11 forwarding needs to be enabled on both the client side and the server side.

`On the client side`, the *-X* (capital X) option to ssh enables X11 forwarding, and you can make this the default (for all connections or for a specific connection) with *ForwardX11 yes* in `~/.ssh/config`.

`On the server side`, *X11Forwarding yes* must be specified in */etc/ssh/sshd_config*. Note that the default is no forwarding (some distributions turn it on in their default /etc/ssh/sshd_config), and that the user cannot override this setting.

\
