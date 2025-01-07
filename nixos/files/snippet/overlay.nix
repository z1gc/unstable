{ config, pkgs, ... }:

let
  # unstable-small is updated more frequently, and is more cutting edge:
  unstableChannel =
    fetchTarball "https://github.com/NixOS/nixpkgs/archive/nixos-unstable-small.tar.gz";

  n9Channel =
    fetchTarball "https://github.com/z1gc/n9/archive/main.tar.gz";

  # https://nixos.wiki/wiki/Overlays
  # The name of `self, super, prev` can be different, may be `final, prev, old`:
  overlay = (self: super: {
    # https://discourse.nixos.org/t/is-it-possible-to-override-cargosha256-in-buildrustpackage/4393/10
    # Rust is kind of "fancy":
    unstable.helix = super.unstable.helix.override (prev: {
      rustPlatform = prev.rustPlatform // {
        buildRustPackage = args: prev.rustPlatform.buildRustPackage (args // {
          patches = (prev.patches or []) ++ [
            (pkgs.fetchpatch {
              name = "z1gc-helix.patch";
              url = "https://github.com/z1gc/helix/commit/09e59e29725b66f55cf5d9be25268924f74004f5.patch";
              hash = "sha256-JBhz0X7/cdRDZ4inasPvxs+xlktH2+cK0190PDxPygE=";
            })
          ];
        });
      };
    });

    # TODO: better way for handling the patches?
    openssh = super.openssh.overrideAttrs (prev: {
      patches = (prev.patches or []) ++ [
        (pkgs.fetchpatch {
          name = "z1gc-openssh.patch";
          url = "https://github.com/z1gc/openssh-portable/commit/b3320c50cb0c74bcc7f0dade450c1660fd09b241.patch";
          hash = "sha256-kiR/1Jz4h4z+fIW9ePgNjEXq0j9kHILPi9UD4JruV7M=";
        })
      ];
    });
  });
in
{
  # https://stackoverflow.com/a/48838322
  config = {
    packageOverrides = pkgs: {
      unstable = import unstableChannel {
        config = config.nixpkgs.config;
      };

      n9 = import n9Channel {};
    };
  };

  overlays = [ overlay ];
}
