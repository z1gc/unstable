# N9

NixOS (partial) configurations of mine.

This provides a simple template to build my machine.

# ()ctothorp

A sample of how to use my configuration (maybe):

```nix
{
  inputs.n9.url = "github:plxty/n9";

  outputs =
    { self, n9, ... }:
    {
      system = "x86_64-linux";

      nixosConfigurations = n9.lib.nixos self {
        packages = [ "btrfs-progs" ];
        modules = with n9.lib.nixos-modules; [
          ./hardware-configuration.nix
          (disk.zfs "/dev/disk/by-id/nvme-eui.002538b231b633a2")
          desktop.gnome
        ];
      };

      homeConfigurations = n9.lib.home self (n9.lib.utils.user2 "byte" ./passwd) {
        packages = [ "jetbrains.clion" ];
        modules = with n9.lib.home-modules; [
          editor.helix
          shell.fish
        ];
      };
    };
}
```

# .*

```nix
{ stdenv, gnumake, ... }:

stdenv.mkDerivation {
  # n-ix, yes, the n9 :O
  pname = "n";
  version = "ix";

  buildInputs = [ gnumake ];
  buildPhase = "make setup";
  installPhase = "make switch";
}
```

Break it!
