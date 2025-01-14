{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, disko, ... }: {
    nixosConfigurations = nixpkgs.lib.genAttrs [
      # FIXME
      # builtins.filter (dir: dir.value == "directory") (lib.lib.attrsToList (builtins.readDir /tmp))
    ] (host: nixpkgs.lib.nixosSystem {
      modules = [
        disko.nixosModules.disko
        ./${host}/hardware-configuration.nix
      ];
    });
  };
}
