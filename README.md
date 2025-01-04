# Unstable

.files of mine, using NixOS.

# .*

Managed by [comtrya](https://github.com/comtrya/comtrya),

```bash
# Defaults to /
./apply.sh evil

# Aha, new stuff
./apply.sh evil /mnt

# Or via network
curl -L https://ptr.ffi.fyi/unstable | bash -s -- evil /mnt

# Full wipe
./apply.sh -p /dev/nvme0n1 evil /mnt
```
