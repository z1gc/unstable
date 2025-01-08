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
  version = "2b988e48f9c41167d1392e2b42262414b839a2ba";

  # have to comment out the hash if the repo is updated (version unchanged):
  src = fetchFromGitHub {
    owner = "z1gc";
    repo = "${pname}";
    rev = version;
    hash = "sha256-aReYhkSyQKibT/YiCcDG90PHi6r4kD9maWAH6a3l/Jo=";
  };

  # filling with `lib.fakeHash` first, then re-run to get the correct hash:
  cargoHash = "sha256-sC0ZVfX5N5xUqq5+/2PwFNEabc3CU3s14qou7QZ1vQU=";
  cargoBuildFlags = [ "--bin" "miniya" ];
  doCheck = false;

  meta = with lib; {
    description = "Configuration Management for Localhost / dotfiles";
    mainProgram = "miniya";
    homepage = "https://github.com/z1gc/miniya";
    license = licenses.mit;
  };
}
