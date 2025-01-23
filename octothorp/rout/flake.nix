# https://krutonium.ca/posts/building-a-nixos-router/
# https://francis.begyn.be/blog/ipv6-nixos-router
# https://github.com/ghostbuster91/blogposts/blob/main/router2023-part2/main.md
# https://nixos.wiki/wiki/Networking
# https://nixos.wiki/wiki/Systemd-networkd

# 10.0.0.1 => Router
# 10.254.0.0 => DHCP
# 10.29.0.0 => PXE (later)
# 10.42.0.0 => Proxy
# May conflicts with?

{
  inputs.n9.url = "../../ampersand";

  outputs =
    {
      self,
      nixpkgs,
      n9,
      ...
    }:
    let
      inherit (nixpkgs) lib;

      ports = {
        # physical
        rj45-0 = "enp1s0";
        rj45-1 = "enp2s0";
        rj45-2 = "enp4s0";
        sfp-0 = "enp5s0f1np1";
        sfp-1 = "enp5s0f0np0";

        # virtual
        vlan = "enp5s0f1.101";
        wan = "pppoe-wan";
        lan = "br-lan";
        iptv = "br-iptv";
      };

      # Without link local address and required online by default:
      mkNetwork =
        port:
        lib.recursiveUpdate {
          networkConfig.LinkLocalAddressing = "no";
          linkConfig.RequiredForOnline = "carrier";
        };

      mkBridge = port: {
        netdevConfig = {
          Kind = "bridge";
          Name = port;
        };
      };
      mkBridgeSlave =
        port: master:
        mkNetwork port {
          matchConfig.Name = port;
          networkConfig.Bridge = master;
          linkConfig.RequiredForOnline = "enslaved";
        };
    in
    {
      system = "x86_64-linux";

      nixosConfigurations = n9.lib.nixos self {
        packages = [
          "bridge-utils"
        ];

        modules = with n9.lib.nixos-modules; [
          ./hardware-configuration.nix
          (disk.btrfs "/dev/nvme0n1")
          (
            { config, ... }:
            {
              boot.kernelModules = [ "pppoe" ];

              networking.useDHCP = false;
              networking.dhcpcd.enable = false;
              systemd.network.enable = true;

              # Netdev:
              systemd.network.netdevs = {
                "10-vlan" = {
                  netdevConfig = {
                    Kind = "vlan";
                    Name = ports.vlan;
                  };
                  vlanConfig.Id = 101;
                };

                "20-lan" = mkBridge ports.lan;
                "21-iptv" = mkBridge ports.iptv;
              };

              # PPPoE, networkd managed as well:
              sops.secrets.pppoe-wan = n9.lib.utils.sopsBinary ./pppoe-wan;
              services.pppd = {
                enable = true;
                # https://man7.org/linux/man-pages/man8/pppd.8.html
                peers.${ports.wan}.config = ''
                  plugin pppoe.so
                  nic-${ports.vlan}
                  file ${config.sops.secrets.pppoe-wan.path}

                  persist
                  maxfail 0
                  holdoff 10

                  +ipv6
                  ipv6 ipv6cp-use-ipaddr
                  noipdefault
                '';
              };

              systemd.network.networks = {
                "10-sfp-0" = mkNetwork ports.sfp-0 {
                  vlan = [ ports.vlan ];
                };

                "20-wan" = mkNetwork ports.wan {
                  networkConfig = {
                    DHCP = "yes";
                    KeepConfiguration = "yes";
                  };
                  linkConfig.RequiredForOnline = "yes";
                };

                "30-rj45-0" = mkBridgeSlave ports.rj45-0 ports.lan;
                "31-rj45-1" = mkBridgeSlave ports.rj45-1 ports.lan;
                "32-sfp-1" = mkBridgeSlave ports.sfp-1 ports.lan;
                "33-lan" = mkNetwork ports.lan {
                  bridgeConfig = { };
                  networkConfig.Address = "10.0.0.1/8";
                };

                "40-rj45-2" = mkBridgeSlave ports.rj45-2 ports.iptv;
                "41-sfp-0" = mkBridgeSlave ports.sfp-0 ports.iptv;
                "42-iptv" = mkNetwork ports.iptv {
                  bridgeConfig = { };
                };
              };

              # DHCP and DNS server (kea?):
              services.dnsmasq = {
                enable = true;
                # https://wiki.archlinux.org/title/Dnsmasq
                settings = {
                  interface = ports.lan;
                  cache-size = "10000";
                  bind-interfaces = true;
                  dhcp-option = [
                    "1,255.0.0.0"
                    "3,10.0.0.1"
                    "6,10.0.0.1"
                  ];
                  dhcp-range = [
                    "10.254.0.1,10.254.254.254,42m"
                    "::,constructor:pppoe-wan,42m"
                  ];
                  dhcp-host = [ ];
                };
              };

              # NAT with nftables.
              # @see nixpkgs/nixos/modules/services/networking/nat-nftables.nix)
              # nix eval --raw ".#nixosConfigurations.rout.config.networking.nftables.tables"
              networking.nftables.enable = true;
              networking.nat = {
                enable = true;
                internalInterfaces = [ ports.lan ];
                externalInterface = ports.wan;
              };
            }
          )
        ];
      };

      homeConfigurations = n9.lib.home self (n9.lib.utils.user2 "byte" ./passwd) {
        packages = [
          "tcpdump"
          "mstflint"
          "ethtool"
          "nftables"
        ];

        modules = with n9.lib.home-modules; [
          editor.helix
          shell.fish
          {
            home.file.".ssh/authorized_keys".text =
              "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILb5cEj9hvj32QeXnCD5za0VLz56yBP3CiA7Kgr1tV5S byte@harm";
          }
        ];
      };
    };
}
