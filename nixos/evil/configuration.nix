# This should be as simple as it can.
# For arguments, you might need to adjust the flake.nix to pass them.

{
  # Required:
  system = "x86_64-linux";
  hostid = "2bff42a7";
  disk.first = "/dev/nvme0n1";
  user = { name = "byte"; uid = 1000; };
  group = { name = "byte"; gid = 1000; };

  # Optional:
  zfs = true;
  gnome = true;
}
