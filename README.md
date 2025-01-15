# N9

Configurations of mine, powered by NixOS + Flake :)

N9 is abbr of N-IX, so freaking bad joke.

# .*

Setup with [nixos-anywhere](https://github.com/nix-community/nixos-anywhere),
try to keep everything in one place.

For setting things up:

```bash
# evil is one of my host. warning: it wipes disk
sudo passwd
curl -L ptr.ffi.fyi/n9 | bash -s -- setup -t root@localhost evil

# rebuild and switch
./burn.sh switch
```

For path structure:

* asterisk: contains scripts to setup secrets, avoid exposing to `/nix/store`
* burn.sh:  helper script for setup machine
* nixos:    everything inside
* pkgs:     some self-maintained packages

Break it!
