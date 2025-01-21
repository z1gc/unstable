{
  inputs.n9.url = "../../irix";

  outputs =
    { self, n9, ... }:
    {
      system = "x86_64-linux"; # to `let`, or to `rec`?

      nixosConfigurations = n9.lib.nixos self {
        inherit (self) system;
        modules = with n9.lib.nixos-modules; [
          ./hardware-configuration.nix
          (disk.zfs "/dev/nvme0n1")
          desktop.gnome
        ];
      };

      homeConfigurations = n9.lib.home "byte" {
        packages = [
          "git-repo"
          "jetbrains.clion"
        ];

        modules = with n9.lib.home-modules; [
          editor.helix
          shell.fish
        ];
      };
    };
}
