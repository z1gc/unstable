# refs:
# https://github.com/NixOS/nixpkgs/blob/master/pkgs/build-support/rust/fetch-cargo-tarball/default.nix

{
  lib,
  fetchFromGitHub,
  rustPlatform,
}:

# To rebuild: rm result && nix-collect-garbage && nix-build . -A comtrya
# (better in the nixos/nix container)
# TODO: better way of rebuilding? These steps will re-copy the dependencies.
rustPlatform.buildRustPackage rec {
  pname = "comtrya";
  version = "687e58262b6aefb1d5b15dde2b927285f9a83487";

  # have to comment out the hash if the repo is updated (version unchanged):
  src = fetchFromGitHub {
    owner = "z1gc";
    repo = "${pname}";
    rev = version;
    hash = "sha256-YQfXymDmtCTBAwe1/Te116QDyW1ADMHmoA5jBQdnF/Y=";
  };

  # filling with `lib.fakeHash` first, then re-run to get the correct hash:
  cargoHash = "sha256-jL88brZPMLQ0aEXNv4ZNn5BeKZe05LaPtmawmq0tqac=";
  cargoBuildFlags = [ "--bin" "comtrya" ];
  doCheck = false;

  meta = with lib; {
    description = "Configuration Management for Localhost / dotfiles";
    mainProgram = "comtrya";
    homepage = "https://github.com/comtrya/comtrya";
    license = licenses.mit;
  };
}
