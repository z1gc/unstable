# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

let
  unstableChannel =
    fetchTarball https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz;

  aptenodytesChannel =
    fetchTarball https://github.com/z1gc/unstable/archive/main.tar.gz;

  # https://nixos.wiki/wiki/Overlays
  # The name of `self, super, prev` can be different, may be `final, prev, old`:
  overlay = (self: super: {
    # https://discourse.nixos.org/t/is-it-possible-to-override-cargosha256-in-buildrustpackage/4393/10
    # Rust is kind of "fancy":
    helix = super.unstable.helix.override (prev: {
      rustPlatform = prev.rustPlatform // {
        buildRustPackage = args: prev.rustPlatform.buildRustPackage (args // {
          patches = (prev.patches or []) ++ [
            (pkgs.fetchpatch {
              name = "z1gc-helix.patch";
              url = "https://github.com/z1gc/helix/commit/09e59e29725b66f55cf5d9be25268924f74004f5.patch";
              hash = "sha256-JBhz0X7/cdRDZ4inasPvxs+xlktH2+cK0190PDxPygE=";
            })
          ];
        });
      };
    });
  });
in
{
  imports =
    [ # nixos-generate-config --show-hardware-config
      ./hardware-configuration.nix
      # {% if variables.machine == "harm" %}
      ./kernel-harm.nix
      # {% endif %}
    ];

  # https://stackoverflow.com/a/48838322
  nixpkgs.config = {
    packageOverrides = pkgs: {
      unstable = import unstableChannel {
        config = config.nixpkgs.config;
      };

      aptenodytes = import aptenodytesChannel {};
    };
  };

  nixpkgs.overlays = [ overlay ];
  nix.settings.substituters =
    [ "https://mirror.sjtu.edu.cn/nix-channels/store" ];

  # https://nixos.wiki/wiki/Btrfs
  fileSystems = {
    "/".options = [ "compress=zstd" ];
    "/home".options = [ "compress=zstd" ];
    "/nix".options = [ "compress=zstd" "noatime" ];
  };

  # systemd-boot
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.efiSysMountPoint = "/efi";
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "{{ variables.machine }}";
  # networking.wireless.enable = true;
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Asia/Shanghai";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  i18n.defaultLocale = "zh_CN.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkb.options in tty.
  # };

  # Enable the X11 windowing system.
  # services.xserver.enable = true;

  # Configure keymap in X11
  # services.xserver.xkb.layout = "us";
  # services.xserver.xkb.options = "eurosign:e,caps:escape";

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  # hardware.pulseaudio.enable = true;
  # OR
  # services.pipewire = {
  #   enable = true;
  #   pulse.enable = true;
  # };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.libinput.enable = true;

  users.groups.byte = {
    gid = 1000;
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.byte = {
    isNormalUser = true;
    uid = 1000;
    group = "byte";
    extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
    packages = with pkgs; [ ]; # Have no idea what should place.
  };

  # programs.firefox.enable = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    wget
    git

    # Not in Stable:
    unstable.helix

    # Penguin!
    aptenodytes.comtrya
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  services.openssh.settings = {
      PermitRootLogin = "yes";
  };

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [ 22 ];
  networking.firewall.allowedUDPPorts = [ ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  system.copySystemConfiguration = true;

  # Not need to worry:
  system.stateVersion = "24.11";
}

