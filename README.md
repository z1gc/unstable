# N9.*

```nix
{ stdenv, gnumake, ... }:

stdenv.mkDerivation {
  # n-ix, yes, the n9 :O
  pname = "n";
  version = "ix";
}
```

NixOS (partial) configurations of mine. Break it!

This provides a simple template to build my machine.

# ()ctothorp

A sample of how to use my configuration (maybe):

```nix
{
  inputs.n9.url = "github:plxty/n9";

  outputs =
    { self, n9, ... }:
    {
      colmenaHive = n9.lib.nixos self "evil" "x86_64-linux" {
        # Shorthand to modules:
        packages = [ "btrfs-progs" ];

        # NixOS modules:
        modules = with n9.lib.nixos-modules; [
          ./hardware-configuration.nix
          (disk.zfs "/dev/disk/by-id/nvme-eui.002538b231b633a2")
          desktop.gnome
        ];

        # Colmena deployment:
        deployment = {
          targetHost = "evil.lan";
          targetUser = "byte";
        };
      };

      homeConfigurations = n9.lib.home self "byte" "/abspath/to/passwd" {
        packages = [ "jetbrains.clion" ];
        modules = with n9.lib.home-modules; [
          editor.helix
          shell.fish
        ];
        deployment.keys = n9.lib.utils.sshKey "/abspath/to/ssh_key";
      };
    };
}
```
