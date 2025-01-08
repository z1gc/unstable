# refs:
# https://github.com/NixOS/nixpkgs/blob/master/pkgs/build-support/rust/fetch-cargo-tarball/default.nix

{
  lib,
  fetchFromGitHub,
  rustPlatform,
}:

# To rebuild: rm result && nix-collect-garbage && nix-build . -A miniya
# (better in the nixos/nix container)
# TODO: better way of rebuilding? These steps will re-copy the dependencies.
rustPlatform.buildRustPackage rec {
  pname = "miniya";
  version = "42a384656724e72e2618547244654041034cf7f3";

  # have to comment out the hash if the repo is updated (version unchanged):
  src = fetchFromGitHub {
    owner = "z1gc";
    repo = "${pname}";
    rev = version;
    hash = "sha256-CZuHtO+DlkoVCDLs9DSefQbr/7yKmCb8tLD7tipDnnY=";
  };

  # filling with `lib.fakeHash` first, then re-run to get the correct hash:
  cargoHash = "sha256-UJOElmjSRIZio1Pq/3dpjqPmrPMkmdMBaUNi/xzPkEg=";
  cargoBuildFlags = [ "--bin" "miniya" ];
  doCheck = false;

  meta = with lib; {
    description = "Configuration Management for Localhost / dotfiles";
    mainProgram = "miniya";
    homepage = "https://github.com/z1gc/miniya";
    license = licenses.mit;
  };
}
