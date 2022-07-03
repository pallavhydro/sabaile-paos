# Passwordless authorisation


## Generate a new Key

`ssh-keygen -t ed25519 -C idiv-USERNAME-$(hostname) -f ~/.ssh/ufz_ed25519`


## Authorize Your Key

`ssh-copy-id -i ~/.ssh/ufz_ed25519 -o PreferredAuthentications=password -o PubkeyAuthentication=no user@frontend1.eve.ufz.de`

Then login to EVE (any frontend). Edit the `~/.ssh/authorized_keys` file and paste in the entire content of the public key from your local machine ie *ufz_ed25519.pub*


## Test passwordless access

`ssh frontend1.eve.ufz.de`

