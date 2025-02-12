{
  self,
  nixpkgs,
  home-manager,
  colmena,
  ...
}@args: # <- Flake inputs

# Make NixOS, with disk, bootloader, networking, hostname, etc.
#
# @input that: Flake `self` of the modules.
# @input hostName: The name you're.
# @input system: The system running.
# @input modules: To nixosSystem.
# @input packages: Shortcut.
# @input deployment: Where you want to deploy?
#
# @output: AttrSet of ${hostName} of ${that}.
#
# Notice, the deployment.keys are uploaded, it means it can't survive next
# reboot if you're using the default option to upload to /run/keys.
that: hostName: system:
{
  modules,
  packages ? [ ],
  deployment ? { },
}: # <- Module arguments

let
  inherit (self.lib) utils;
  inherit (nixpkgs) lib;

  hostId = builtins.substring 63 8 (builtins.hashString "sha512" hostName);
  hasColmena = that ? colmenaHive;
  hasHome = that ? homeConfigurations;
  homeConfig = that.homeConfigurations.${hostName};

  subModules =
    [
      (import ../pkgs/nixpkgs.nix args)
      (
        { pkgs, ... }:
        {
          nix.settings = {
            experimental-features = [
              "nix-command"
              "flakes"
            ];
            substituters = [ "https://mirrors.ustc.edu.cn/nix-channels/store" ];
          };

          boot.loader = {
            systemd-boot.enable = true;
            efi.canTouchEfiVariables = true;
          };

          # For default networking, using NixOS's default (dhcpcd).
          networking = {
            inherit hostName hostId;
          };

          environment = {
            sessionVariables.NIX_CRATES_INDEX = "sparse+https://mirrors.ustc.edu.cn/crates.io-index/";

            systemPackages =
              with pkgs;
              [
                git
              ]
              ++ (map (utils.attrByIfStringPath pkgs) packages);
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
          services.openssh = {
            enable = true;
            ports = [ 22 ];
            authorizedKeysFiles = [ "/etc/ssh/agent_keys.d/%u" ];
          };
          networking.firewall.allowedTCPPorts = [ 22 ];

          # Fine-gran control of which user can use PAM to authorize things.
          security.pam = {
            sshAgentAuth = {
              enable = true;
              authorizedKeysFiles = [ "/etc/ssh/agent_keys.d/%u" ];
            };
            services.sudo.sshAgentAuth = true;
          };
        }
      )

      home-manager.nixosModules.home-manager
      {
        # https://discourse.nixos.org/t/users-users-name-packages-vs-home-manager-packages/22240/2
        home-manager.useUserPackages = true;
        home-manager.useGlobalPkgs = true;
      }
    ]
    ++ (lib.optionals hasHome (
      (lib.mapAttrsToList (
        username:
        {
          user,
          group,
          config,
          ...
        }:
        # { pkgs, ... }:
        assert lib.assertMsg (username != "root") "can't manage root!";
        {
          users = {
            groups.${username} = group;
            users.${username} = user;
          };

          home-manager.users.${username} = config;
        }
      ) homeConfig)
      ++ [
        { users.users.root.hashedPassword = "!"; }
      ]
    ))
    ++ (lib.optionals (deployment ? targetUser && deployment ? targetKey) [
      (
        { pkgs, ... }:
        let
          user = deployment.targetUser;
          uid = 27007;
          allow = command: {
            inherit command;
            options = [ "SETENV" ];
          };
          store = "/nix/store/[[\\:alnum\\:]-.]*";
        in
        {
          users.groups.${user}.gid = uid;
          users.users.${user} = {
            isSystemUser = true;
            inherit uid;
            group = user;
            shell = pkgs.bash;
            hashedPassword = "!";
          };

          environment.etc."ssh/agent_keys.d/${user}" = {
            text = deployment.targetKey;
            mode = "0644";
          };
          security.sudo.extraRules = [
            {
              users = [ deployment.targetUser ];
              runAs = "root";
              commands = [
                # FIXME: Restrict using systemd-run or other sandboxie?
                (allow "/run/current-system/sw/bin/sh -c *")
                (allow "/run/current-system/sw/bin/nix-env --profile /nix/var/nix/profiles/system --set ${store}")
                (allow "${store}/bin/switch-to-configuration switch")

                # For buildOnTarget == true:
                (allow "/run/current-system/sw/bin/nix-store --no-gc-warning --realise ${store}")
              ];
            }
          ];
          nix.settings.trusted-users = [ user ];
        }
      )
    ])
    ++ modules;

  combined = nixpkgs.lib.recursiveUpdate {
    allowLocalDeployment = true;
    keys = lib.optionalAttrs hasHome (
      lib.fold (a: b: a.deployment.keys // b) { } (lib.attrValues homeConfig)
    );
  } (builtins.removeAttrs deployment [ "targetKey" ]);
in
{
  # For home.nix, n9 requires one-to-one configuration, can only have 1 host:
  passthru = {
    inherit hostName system;
  };
}
// (
  if hasColmena then
    (if (that.colmenaBulk or false) then lib.id else colmena.lib.makeHive) {
      meta =
        let
          nodeNixpkgs = nixpkgs.legacyPackages.${system};
        in
        {
          nixpkgs = nodeNixpkgs;
          nodeNixpkgs.${hostName} = nodeNixpkgs;
        };

      "${hostName}" = {
        imports = subModules;
        deployment = combined;
      };
    }
  else
    {
      "${hostName}" = lib.nixosSystem {
        inherit system;
        modules = subModules;
      };
    }
)
