{
  lib,
  fetchFromGitHub,
  rustPlatform,
}:

rustPlatform.buildRustPackage rec {
  pname = "comtrya";
  version = "unstable";

  # have to comment out the hash if the repo is updated (version unchanged):
  src = fetchFromGitHub {
    owner = "z1gc";
    repo = "${pname}";
    rev = "0826a2448da8cecbf48ec4fc592ec535d9baf779";
    hash = "sha256-dihTrnEl/Ws+7jzxwRx+tQ5RYcdlMo7IaVy07DhoD7Y=";
  };

  cargoHash = "sha256-ezQ6r+dL9qk1wos31uhzkDv5AAnSFdtZjWKyHXOlOYU=";
  doCheck = false;

  meta = with lib; {
    description = "Configuration Management for Localhost / dotfiles";
    mainProgram = "comtrya";
    homepage = "https://github.com/comtrya/comtrya";
    license = with licenses; [ mit ];
  };
}
