# https://github.com/starside/Nix-On-Hyper-V-Gen-2-X-Elite/tree/main
# https://github.com/NixOS/nixpkgs/blob/master/pkgs/os-specific/linux/kernel/linux-rt-6.6.nix
{ pkgs, modulesPath, lib, ... }:

let
  wslKernelPackage = { fetchgit, buildLinux, ... } @ args:
    buildLinux (args // rec {
      version = "6.6.36.3";
      modDirVersion = version;

      src = fetchgit {
        url = "https://github.com/microsoft/WSL2-Linux-Kernel.git";
        rev = "149cbd13f7c04e5a9343532590866f31b5844c70";
        hash = "sha256-kNNEJ81rlM0ns+bdiiSpYcM2hZUFjXb7EgGgHEI7b04";
      };

      structuredExtraConfig =
        with lib.kernel;
        {
          CONFIG_HYPERV_VSOCKETS = yes;
          CONFIG_PCI_HYPERV = yes;
          CONFIG_PCI_HYPERV_INTERFACE = yes;
          CONFIG_HYPERV_STORAGE = yes;
          CONFIG_HYPERV_NET = yes;
          CONFIG_HYPERV_KEYBOARD = yes;
          CONFIG_FB_HYPERV = yes;
          CONFIG_HID_HYPERV_MOUSE = yes;
          CONFIG_HYPERV = yes;
          CONFIG_HYPERV_TIMER = yes;
          CONFIG_HYPERV_UTILS = yes;
          CONFIG_HYPERV_BALLOON = yes;
        }
        // structuredExtraConfig;

      extraMeta.branch = "6.6";
    } // (args.argsOverride or {}));
  wslKernel = pkgs.callPackage wslKernelPackage {};
in
{
  boot.kernelPackages =
    pkgs.recurseIntoAttrs (pkgs.linuxPackagesFor wslKernel);

  virtualisation.hypervGuest = {
    enable = true;
    videoMode = "1024x768";
  };
}
