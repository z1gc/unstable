# N9

.files of mine, mainly using NixOS.

N9 is abbr of N-IX, so freaking bad joke.

# .*

Managed by [miniya](https://github.com/z1gc/miniya), a simplified fork version
of [comtrya](https://github.com/comtrya/comtrya).

```bash
# Defaults to /
./apply.sh evil

# Aha, new stuff
./apply.sh evil /mnt

# Or via network
curl -L https://ptr.ffi.fyi/n9 | bash -s -- evil /mnt

# Full wipe
./apply.sh -p /dev/nvme0n1 -w evil /mnt
```
