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
  version = "7f640c438fd8686928d311ec92a330d52f3c04a8";

  # have to comment out the hash if the repo is updated (version unchanged):
  src = fetchFromGitHub {
    owner = "z1gc";
    repo = "${pname}";
    rev = version;
    hash = "sha256-Wy8h2v3bR2E09JasVx/5e4pgxm9idCctZy1tiJwDPhs=";
  };

  # filling with `lib.fakeHash` first, then re-run to get the correct hash:
  cargoHash = "sha256-bWmcXLCbMC2US+l+kFrrkjs1zLfx/d36NgtLE1FkzaA=";
  cargoBuildFlags = [ "--bin" "miniya" ];
  doCheck = false;

  meta = with lib; {
    description = "Configuration Management for Localhost / dotfiles";
    mainProgram = "miniya";
    homepage = "https://github.com/z1gc/miniya";
    license = licenses.mit;
  };
}
