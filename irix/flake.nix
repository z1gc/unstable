# Library of N9, IR(N)IX.
# Devices should rely on this for modular.
# TODO: Mo(re)dules, when more devices.

{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { ... }@args:
    let
      # TODO: Modular!
      disk =
        args: type: device:
        (import ./disk args) { inherit type device; };
    in
    {
      # NixOS, Nix (For package manager only, use lib.mkNixPackager?):
      # TODO: With no hard code?
      lib.nixos = import ./nixos.nix args;
      lib.nixos-modules = {
        disk.zfs = disk args "zfs";
        disk.btrfs = disk args "btrfs";
        desktop.gnome = import ./desktop/gnome.nix args;
      };

      # User/home level modules, with home-manager:
      lib.home = import ./home.nix args;
      lib.home-modules = {
        editor.helix = import ./editor/helix.nix args;
        shell.fish = import ./shell/fish.nix args;
      };
    }
    // args;
}
