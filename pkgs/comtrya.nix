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
  version = "b6541726b6c3ee7fec2e8350ccd0689ce9a0d78f";

  # have to comment out the hash if the repo is updated (version unchanged):
  src = fetchFromGitHub {
    owner = "z1gc";
    repo = "${pname}";
    rev = version;
    hash = "sha256-pkrHY97paYBaSnox55BOHPsH6RWpwXaGl4d6ymBPwL0=";
  };

  # filling with `lib.fakeHash` first, then re-run to get the correct hash:
  cargoHash = "sha256-eAaoZb0ch1/QL5KF739Hzxh/dqZ36RYSGk+yKhI/PBI=";
  cargoBuildFlags = [ "--bin" "comtrya" ];
  doCheck = false;

  meta = with lib; {
    description = "Configuration Management for Localhost / dotfiles";
    mainProgram = "comtrya";
    homepage = "https://github.com/comtrya/comtrya";
    license = licenses.mit;
  };
}
