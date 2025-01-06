{
  lib,
  fetchFromGitHub,
  rustPlatform,
}:

# To rebuild: rm result && nix-collect-garbage
# Then build: nix-build . -A comtrya
# TODO: better way of rebuilding? These steps will re-copy the dependencies.
rustPlatform.buildRustPackage rec {
  pname = "comtrya";
  version = "git";

  # have to comment out the hash if the repo is updated (version unchanged):
  src = fetchFromGitHub {
    owner = "z1gc";
    repo = "${pname}";
    rev = "f7baf7974fc0d47327121eb547c0e55593609a72";
    hash = "sha256-+/EQYS2J0awdjmqJQvKwfJkRLt/lbtMwJLDsW38A6M8=";
  };

  cargoHash = "sha256-ak2HnBpsuzq04uwOTDBTO8KRjajsLfyfY10SdrUX4qY=";
  doCheck = false;

  meta = with lib; {
    description = "Configuration Management for Localhost / dotfiles";
    mainProgram = "comtrya";
    homepage = "https://github.com/comtrya/comtrya";
    license = with licenses; [ mit ];
  };
}
