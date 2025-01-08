{
  system ? builtins.currentSystem,
  pkgs ? import <nixpkgs> { inherit system; }
}:

# TODO: Try moving to pkgs?
let
  callPackage = pkgs.lib.callPackageWith (pkgs // self);
  self = {
    miniya = callPackage ./pkgs/miniya.nix {};
  };
in
  self
