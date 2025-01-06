# refs:
# https://github.com/NixOS/nixpkgs/blob/master/pkgs/build-support/rust/fetch-cargo-tarball/default.nix

{
  lib,
  fetchFromGitHub,
  rustPlatform,
}:

# To rebuild: rm result && nix-collect-garbage
# Then build: nix-build . -A comtrya
# TODO: better way of rebuilding? These steps will re-copy the dependencies.
# You might want to `export NIX_CRATES_INDEX=<mirror_of_crates_io>` first.
rustPlatform.buildRustPackage rec {
  pname = "comtrya";
  version = "git";

  # have to comment out the hash if the repo is updated (version unchanged):
  src = fetchFromGitHub {
    owner = "z1gc";
    repo = "${pname}";
    rev = "8c05cf81f35fa0e5faefe4ce3f61407725ad81d7";
    hash = "sha256-D06qvKCaX7eRpNIHmyKOAFclVQvL+7/+V0290HR/Q9w=";
  };

  cargoHash = "sha256-ak2HnBpsuzq04uwOTDBTO8KRjajsLfyfY10SdrUX4qY=";
  doCheck = false;

  meta = with lib; {
    description = "Configuration Management for Localhost / dotfiles";
    mainProgram = "comtrya";
    homepage = "https://github.com/comtrya/comtrya";
    license = licenses.mit;
  };
}
