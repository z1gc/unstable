# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ pkgs, lib, ... }:

let
  homeManagerChannel =
    fetchTarball
      "https://github.com/nix-community/home-manager/archive/release-{{ variables.channel }}.tar.gz";
in
{
  imports =
    [
      "${homeManagerChannel}/nixos"
      # nixos-generate-config --show-hardware-config
      ./hardware-configuration.nix
      # {% if vars.hyperv and vars.arm64 %}
      ./kernel-harm.nix
      # {% endif %}
    ];

  nix.settings.substituters =
    [ "https://mirror.sjtu.edu.cn/nix-channels/store" ];

  nixpkgs = import ./snippet/overlay.nix;

  environment.variables = {
    NIX_CRATES_INDEX = "sparse+https://mirrors.ustc.edu.cn/crates.io-index/";
  };

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

  # Network:
  networking.hostName = "{{ vars.machine }}";
  # networking.wireless.enable = true;
  networking.networkmanager.enable = true;

  # Locale:
  time.timeZone = "Asia/Shanghai";
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

  users.groups = lib.genAttrs [ "{{ vars.group }}" ] (group: {
    group.gid = "{{ vars.gid }}";
  });

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users = lib.genAttrs [ "{{ vars.user }}" ] (user: {
    user = {
      isNormalUser = true;
      uid = "{{ vars.uid }}";
      group = "{{ vars.group }}";
      extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
      packages = [ ]; # Have no idea what should place.
    };
  });

  # List packages installed in system profile. To search: nix search wget
  environment.systemPackages = with pkgs; [
    zoxide
    git
    nixd
    ripgrep
    fd
    fzf

    # Not in Stable:
    unstable.helix

    # Penguin!
    n9.comtrya
  ];

  # Not need to worry, as well:
  home-manager.users = lib.genAttrs [ "{{ vars.user }}" ] (user: {
    user.home.stateVersion = "24.11";
    user.programs.fish = import ./snippet/fish.nix;
  });

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  services.openssh.settings = {
      PermitRootLogin = "yes";
  };

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [ 22 ];
  networking.firewall.allowedUDPPorts = [ ];

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  system.copySystemConfiguration = true;

  # Not need to worry:
  system.stateVersion = "24.11";
}
