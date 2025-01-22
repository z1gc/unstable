# https://github.com/astro/nix-openwrt-imagebuilder
# https://github.com/astro/nix-openwrt-imagebuilder/blob/main/example-x86-64.nix
# https://downloads.openwrt.org/releases/23.05.5/targets/x86/64/profiles.json
# nix eval --raw ".#default.configurePhase"
# WIP

{
  inputs = {
    openwrt-imagebuilder.url = "github:astro/nix-openwrt-imagebuilder";
  };
  outputs =
    { nixpkgs, openwrt-imagebuilder, ... }:
    {
      # default is the build name, use `nix flake show` to know.
      packages.x86_64-linux.default =
        let
          inherit (nixpkgs) lib;

          target = "x86";
          variant = "64";
          profile = "generic";

          # Try to remove all kmods, the profiles is cached from `profiles.json`
          # to `cached-profiles/${version}.nix`, and when building, the real
          # profiles will be fetched by `fetchurl`. That's fine because OpenWRT
          # will seldomly change the profiles, and it's quite stable within a
          # major version.
          cachedProfile =
            (import "${openwrt-imagebuilder}/profiles.nix" { }).allProfiles.${target}.${variant};
          removes = builtins.map (pkg: "-${pkg}") (
            builtins.filter (lib.hasPrefix "kmod-") (
              cachedProfile.default_packages ++ cachedProfile.profiles.${profile}.device_packages
            )
          );

          pkgs = nixpkgs.legacyPackages.x86_64-linux;

          config = {
            inherit
              target
              variant
              profile
              pkgs
              ;

            # add package to include in the image, ie. packages that you don't
            # want to install manually later
            packages = [ "tcpdump" ] ++ removes;

            disabledServices = [ "dropbear" ];

            # include files in the images.
            # to set UCI configuration, create a uci-defauts scripts as per
            # official OpenWRT ImageBuilder recommendation.
            files = pkgs.runCommand "image-files" { } ''
              mkdir -p $out/etc/uci-defaults
              cat > $out/etc/uci-defaults/99-custom <<EOF
              uci -q batch << EOI
              set system.@system[0].hostname='testap'
              commit
              EOI
              EOF
            '';
          };

          # TODO: new options?
          overrides = {
            TARGET_ROOTFS_SQUASHFS = "n";
            TARGET_ROOTFS_EXT4FS = "n";
            GRUB_IMAGES = "n";
            GRUB_EFI_IMAGES = "n";
          };

          package = openwrt-imagebuilder.lib.build config;
        in
        package.overrideAttrs (prev: {
          preBuild =
            (prev.preBuild or "")
            + (builtins.concatStringsSep " " (
              [ "sed -i -E -e ''" ]
              ++ (builtins.map ({ name, value }: "-e 's/^(CONFIG_${name}=).+$/\\1${value}/'") (
                lib.attrsToList overrides
              ))
              ++ [ ".config" ]
            ));

          preInstall = "rm -fv bin/targets/${target}/${variant}/*-kernel.bin";
          postInstall = "cp .config $out/openwrt-config";
        });
    };
}
