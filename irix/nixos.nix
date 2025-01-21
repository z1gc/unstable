{
  nixpkgs,
  home-manager,
  sops-nix,
  ...
}: # <- Flake inputs

# Make NixOS, with disk, bootloader, networking, hostname, etc.
# TODO: mkIf style configurations? It loses flexibility.
# @input that: Flake `self` of the modules.
# @input args.{system,modules}: To nixosSystem.
# @output: AttrSet of ${hostName} of ${that}.
that: # <- Module arguments

{ system, ... }@args: # <- NixOS `nixosSystem {}` (Hmm, not really)
let
  pkgs = nixpkgs.legacyPackages.${system};
  lib = nixpkgs.lib;

  hostName = builtins.unsafeDiscardStringContext (builtins.baseNameOf that);
  hostId = builtins.substring 63 8 (builtins.hashString "sha512" hostName);

  packer = {
    nixpkgs.overlays = [
      (self: super: {
        helix = super.helix.overrideAttrs (prev: {
          patches = (prev.patches or [ ]) ++ [
            (pkgs.fetchpatch {
              url = "https://github.com/z1gc/helix/commit/16bff48d998d01d87f41821451b852eb2a8cf627.patch";
              hash = "sha256-JBhz0X7/cdRDZ4inasPvxs+xlktH2+cK0190PDxPygE=";
            })
          ];
        });

        openssh = super.openssh.overrideAttrs (prev: {
          patches = (prev.patches or [ ]) ++ [
            (pkgs.fetchpatch {
              url = "https://github.com/z1gc/openssh-portable/commit/b3320c50cb0c74bcc7f0dade450c1660fd09b241.patch";
              hash = "sha256-kiR/1Jz4h4z+fIW9ePgNjEXq0j9kHILPi9UD4JruV7M=";
            })
          ];
        });
      })
    ];

    nix.settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      substituters = [ "https://mirrors.ustc.edu.cn/nix-channels/store" ];
    };

    nixpkgs.config.allowUnfree = true;
  };

  basic = {
    boot.loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };

    networking = {
      inherit hostName hostId;
      networkmanager.enable = true;
    };

    environment = {
      sessionVariables.NIX_CRATES_INDEX = "sparse+https://mirrors.ustc.edu.cn/crates.io-index/";

      systemPackages = with pkgs; [
        gnumake
        git
        helix
      ];
    };

    time.timeZone = "Asia/Shanghai";
    i18n.defaultLocale = "zh_CN.UTF-8";

    virtualisation = {
      containers.enable = true;
      podman = {
        enable = true;
        defaultNetwork.settings.dns_enabled = true;
      };
    };

    system.stateVersion = "25.05";

    # TODO: To other places.
    networking = {
      firewall.allowedTCPPorts = [ 22 ];
      firewall.allowedUDPPorts = [ ];
    };

    services.openssh = {
      enable = true;
      ports = [ 22 ];
    };
  };

  home =
    if that ? homeConfigurations then
      [
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
        }
      ]
      ++ (lib.mapAttrsToList (
        user:
        {
          group,
          uid,
          gid,
          home,
          config,
        }:
        {
          users = {
            groups.${group} = {
              inherit gid;
            };

            users.${user} = {
              isNormalUser = true;
              inherit uid group home;
              extraGroups = [ "wheel" ];
            };
          };

          home-manager.users.${user} = config;
        }
      ) that.homeConfigurations)
    else
      [ ];
in
{
  ${hostName} =
    nixpkgs.lib.nixosSystem {
      inherit system;

      modules =
        [
          packer
          basic
          sops-nix.nixosModules.sops
        ]
        ++ home
        ++ args.modules;
    }
    // builtins.removeAttrs args [ "modules" ];
}
