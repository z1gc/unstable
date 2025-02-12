{ ... }: # <- Flake inputs

# Enable password-less ssh agent auth for sudo (or other services).
# @input programs: Which program (affected by PAM) will be used, e.g. ["sudo"]
programs: # <- Module arguments

{ lib, ... }: # <- Nix `imports = []`
{
  # https://discourse.nixos.org/t/remote-nixos-rebuild-sudo-askpass-problem/28830/11
  # For ssh client, you should setup a ssh-agent first.
  security.pam = {
    sshAgentAuth.enable = true;
    services = lib.fold (
      a: b:
      {
        "${a}".sshAgentAuth = true;
      }
      // b
    ) { } programs;
  };
}
