# Restoring TMUX sessions

Author: Pallav Kumar Shrestha, CHS
Date  : 20.12.21

- This file guides you through setup a system such that you can save your tmux sessions after the server gets killed i.e. EVE maintenance. 
- This is also quite useful in case you use tmux sessions on your laptop for convinience. Now with this setup you can resurrect them after restarting your laptop as well!
- The setup consists of installing TPM, followed by installing tmux-resurrect and finally THE test.


## Requirements

- `tmux` version 1.9 or greater
- `git`
- `bash` (but works for me in `fish` as well)


0. [EVE only] Load newer tmux on EVE

```
module load GCCcore/10.2.0 tmux/3.2
```

Note: I will request Toni (WKDV) to make tmux 3.2 as default in future. The current default is 1.8, which is not compatible with TPM or tmux-resurrect. I have added this line to the end of my `.bashrc` for now as a quick-fix.



1. Install TPM - tmux plugin manager

Source: `https://github.com/tmux-plugins/tpm`
Note: If you already have this, skip to next heading

1.1 Clone TPM to your home

```
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

1.2 Edit your `~/.tmux.conf`. If you don't have one, create it and add the following:

```
# List of plugins
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-sensible'

# Initialize TMUX plugin manager (keep this line at the very bottom of tmux.conf)
run '~/.tmux/plugins/tpm/tpm'
``` 

1.3 Source the tmux environment i.e. `.tmux.conf`

```
tmux source ~/.tmux.conf
```


2. Install tmux-resurrect

Source: `https://github.com/tmux-plugins/tmux-resurrect`
Note  : This plugin magically saves and resurrents all your tmux sessions.


2.1 Add plugin to the list of TPM plugins in `.tmux.conf` by addin the following line -

```
set -g @plugin 'tmux-plugins/tmux-resurrect'
```

2.2 Enter tmux and type the following to fetch the plugin and source it. If you haven't changed the prefix, then that would be `ctrl-b`. You should get some "TMUX environment reloaded" message from tmux, which means tmux-resurrect has been installed and is ready to be used!

```
tmux

prefix + I

# note that its a capital I as in Integer
```


3. Test saving and restoring your tmux sessions
 
3.1 While inside of one of your tmux sessions, type the following to save all of your tmux session as is.

```
prefix + ctrl-s
```

3.2 When your tmux sessions are gone (e.g. after EVE maintenance or Laptop restart), type the following to restore your tmux sessions to previous state:

```
prefix + ctrl-r
```




