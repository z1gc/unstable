# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

let
  # unstable-small is updated more frequently, and is more cutting edge:
  unstableChannel =
    fetchTarball "https://github.com/NixOS/nixpkgs/archive/nixos-unstable-small.tar.gz";

  homeManagerChannel =
    fetchTarball
      "https://github.com/nix-community/home-manager/archive/release-{{ variables.channel }}.tar.gz";

  n9Channel =
    fetchTarball "https://github.com/z1gc/n9/archive/main.tar.gz";

  # https://nixos.wiki/wiki/Overlays
  # The name of `self, super, prev` can be different, may be `final, prev, old`:
  overlay = (self: super: {
    # https://discourse.nixos.org/t/is-it-possible-to-override-cargosha256-in-buildrustpackage/4393/10
    # Rust is kind of "fancy":
    unstable.helix = super.unstable.helix.override (prev: {
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

    # TODO: better way for handling the patches?
    openssh = super.openssh.overrideAttrs (prev: {
      patches = (prev.patches or []) ++ [
        (pkgs.fetchpatch {
          name = "z1gc-openssh.patch";
          url = "https://github.com/z1gc/openssh-portable/commit/b3320c50cb0c74bcc7f0dade450c1660fd09b241.patch";
          hash = "sha256-kiR/1Jz4h4z+fIW9ePgNjEXq0j9kHILPi9UD4JruV7M=";
        })
      ];
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
      "${homeManagerChannel}/nixos"
    ];

  # https://stackoverflow.com/a/48838322
  nixpkgs.config = {
    packageOverrides = pkgs: {
      unstable = import unstableChannel {
        config = config.nixpkgs.config;
      };

      n9 = import n9Channel {};
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
    packages = [ ]; # Have no idea what should place.
  };

  # programs.firefox.enable = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    zoxide
    git
    nixd

    # Not in Stable:
    unstable.helix

    # Penguin!
    n9.comtrya
  ];

  # TODO: File with home.nix? May not use nix outside the NixOS, because they're everywhere :)
  home-manager.users.byte = { ... }: {
    programs.fish = {
      enable = true;
      plugins = [
        {
          name = "autols";
          src = pkgs.fetchFromGitHub {
            owner = "kpbaks";
            repo = "autols.fish";
            rev = "fe2693e80558550e0d995856332b280eb86fde19";
            hash = "sha256-EPgvY8gozMzai0qeDH2dvB4tVvzVqfEtPewgXH6SPGs=";
          };
        }
        {
          name = "upto";
          src = pkgs.fetchFromGitHub {
            owner = "Markcial";
            repo = "upto";
            rev = "2d1f35453fb55747d50da8c1cb1809840f99a646";
            hash = "sha256-Lv2XtP2x9dkIkUUjMBWVpAs/l55Ztu7gIjKYH6ZzK4s=";
          };
        }
        {
          name = "fzf";
          src = pkgs.fetchFromGitHub {
            owner = "PatrickF1";
            repo = "fzf.fish";
            rev = "8920367cf85eee5218cc25a11e209d46e2591e7a";
            hash = "sha256-T8KYLA/r/gOKvAivKRoeqIwE2pINlxFQtZJHpOy9GMM=";
          };
        }
      ];

      functions = {
        _fzf_search_ripgrep = {
          body = ''
            # Copy from '_fzf_search_directory':
            set -f token (commandline --current-token)
            # expand any variables or leading tilde (~) in the token
            set -f expanded_token (eval echo -- $token)
            # unescape token because it's already quoted so backslashes will mess up the path
            set -f unescaped_exp_token (string unescape -- $expanded_token)

            # If token empty, don't fresh the result:
            set -l rg_cmd rg --column --line-number --no-heading --color=always
            if test "$unescaped_exp_token" = ""
              set -f fzf_cmd "cat /dev/null"
            else
              set -f fzf_cmd "$rg_cmd \"$unescaped_exp_token\""
            end

            # https://codeberg.org/tplasdio/rgfzf/src/branch/main/rgfzf
            # TODO: Save queries for both ripgrep and fzf:
            set -f file_paths_selected (FZF_DEFAULT_COMMAND="$fzf_cmd" \
              _fzf_wrapper --multi --ansi --delimiter : --layout=reverse --header-first --marker="*" \
              --query "$unescaped_exp_token" \
              --disabled \
              --bind "alt-k:clear-query" \
              --bind "ctrl-y:unbind(change,ctrl-y)+change-prompt(fzf: )+enable-search+clear-query+rebind(ctrl-r)" \
              --bind "ctrl-r:unbind(ctrl-r)+change-prompt(rg: )+disable-search+clear-query+reload($rg_cmd {q} || true)+rebind(change,ctrl-y)" \
              --bind "change:reload:sleep 0.2; $rg_cmd {q} || true" \
              --prompt "rg: " \
              --header "switch: rg (ctrl+r) / fzf (ctrl+y)" \
              --preview 'bat --color=always {1} --highlight-line {2} --line-range $(math max {2}-15,0):' \
              --preview-window 'down,60%,noborder,+{2}+3/3,-3' | cut -s -d: -f1-3)

            if test $status -eq 0
              commandline --current-token --replace -- (string escape -- $file_paths_selected | string join ' ')
            end

            commandline --function repaint
          '';
        };

        _fzf_switch_common = {
          body = ''
            set -l indicator $argv[1]

            # abbr doesn't play very well with commandline...
            switch (commandline -t)
              case fd
                set -u fzf_fd_opts
                set -f func _fzf_search_directory
              case fa
                set -g fzf_fd_opts --hidden --no-ignore
                set -f func _fzf_search_directory
              case re
                set -f func _fzf_search_ripgrep
              case p
                set -f func _fzf_search_processes
              case gs
                set -f func _fzf_search_git_status
              case gl
                set -f func _fzf_search_git_log
              case '*'
                commandline -i "$indicator"
                return
            end

            if test "$indicator" = ";"
              commandline -rt ""
            else
              # Remove the last token of commandline, TODO: performance?
              set -l tokens (commandline -o)[1..-2]
              commandline -r (string join ' ' $tokens)
            end

            $func
          '';
        };

        fish_prompt = {
          body = ''
            set -g fish_last_status $status
            set -l host ""
            if set -q SSH_TTY
              set host "@"(string split -f1 -m1 ' ' $SSH_CONNECTION)
            end

            printf "\033[K"
            set_color brblack
            echo -n '['(prompt_pwd -d 0)"]$host"
            echo -n (fish_vcs_prompt)
            echo

            echo -n (string repeat -n $SHLVL '$')
            echo -n ' '
            set_color normal
          '';
        };

        fish_right_prompt = {
          body = ''
            # https://github.com/fish-shell/fish-shell/issues/1706#issuecomment-2430550184
            tput sc
            tput cuu1
            tput cuf 2

            if test $fish_last_status -ne 0
              set_color red
              echo -n "$fish_last_status"
              set_color brblack
              echo -n " | "
            else
              set_color brblack
            end

            if test $CMD_DURATION -ne 0
              # https://unix.stackexchange.com/a/27014
              set -l d (math -s 0 $CMD_DURATION / 1000 / 60 / 60 / 24)
              set -l h (math -s 0 $CMD_DURATION / 1000 / 60 / 60 % 24)
              set -l m (math -s 0 $CMD_DURATION / 1000 / 60 % 60)
              set -l s (math -s 0 $CMD_DURATION / 1000 % 60)
              set -l ms (math -s 0 $CMD_DURATION % 1000)

              test $d -gt 0 && echo -n "$d""d"
              test $h -gt 0 && echo -n "$h""h"
              test $m -gt 0 && echo -n "$m""m"
              test $s -gt 0 && echo -n "$s""s"
              echo -n "$ms""ms | "
            end
            echo -n (date +"%F%%%T")

            tput rc

            # Can place other info in the second line right prompt :)
            set_color normal
          '';
        };
      };

      shellInitLast = ''
        # Fish style
        set __fish_git_prompt_showdirtystate yes
        set __fish_git_prompt_showstashstate yes
        set __fish_git_prompt_showuntrackedfiles yes
        set __fish_git_prompt_showupstream informative
        set __fish_git_prompt_describe_style default

        # Z
        zoxide init fish | source

        # fzf
        set -g fzf_directory_opts --bind "alt-k:clear-query"
        bind --mode default ';' '_fzf_switch_common ";"' # e.g. f;, h;, ...
        bind --mode default ':' '_fzf_switch_common ":"' # accept previous token as argument

        # Remove flashing colors, https://linux.overshoot.tv/wiki/ls
        set -gx LS_COLORS (string replace -a '05;' "" "$LS_COLORS")

        # Autols, workaround
        set -g __autols_last_dir "$PWD"
        emit autols_uninstall
        emit autols_install
      '';

      shellAbbrs = {
        n9s = "sudo nixos-rebuild switch";
        n9u = "sudo nixos-rebuild switch --upgrade";

        hi = "hx .";
        ra = "rg --hidden --no-ignore";
        ff = "fd --type f .";
        up = "upto";
        ze = "zoxide query";
      };
    };

    # Not need to worry, as well:
    home.stateVersion = "24.11";
  };

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
