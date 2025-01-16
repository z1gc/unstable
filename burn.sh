#!/usr/bin/env bash
# Wrapper of nixos-anywhere and nixos-rebuild.
# TODO: Install as a nix package.

set -ue

# Affects only local machine:
function sudo() {
  if [[ "$USER" == "root" ]]; then
    "$@"
  elif [[ -e /etc/NIXOS ]]; then
    $(which sudo) "$@"
  else
    $(which sudo) -i bash -c "cd $PWD && $(printf '"%s" ' "$@")"
  fi
}

# TODO: nixops? Or using python.
function ssh() {
  local ssh="$1" port="$2"
  shift 2

  if [[ "$ssh" != "" ]]; then
    local args=(-t -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no)
    if [[ "$port" != "" ]]; then
      args+=(-p "$port")
    fi

    # shellcheck disable=SC2087
    $(which ssh) "${args[@]}" "$ssh" bash <<EOF
set -eu
export PATH="\$PATH:/run/current-system/sw/bin"
$@
EOF
  else
    "$@"
  fi
}

function nixos-anywhere() {
  # shellcheck disable=SC2155
  local bin="$(which nixos-anywhere)"
  if [[ "$bin" != "" ]]; then
    sudo "$bin" "$@"
  else
    sudo nix run --extra-experimental-features "nix-command flakes" \
      github:nix-community/nixos-anywhere -- "$@"
  fi
}

function nixos-hardware() {
  local ssh="$1" port="$2" hostname="$3" \
    cmd=(sudo nixos-generate-config --no-filesystems --show-hardware-config)

  ssh "$ssh" "$port" "${cmd[@]}" > "dev/$hostname/hardware-configuration.nix"
}

function nixos-clean() {
  local ssh="$1" port="$2"
  ssh "$ssh" "$port" sudo nix-env --delete-generations +7
  # TODO: Keep result for faster rebuild?
  # ssh "$ssh" "$port" sudo nix-store --gc
}

function setup() {
  local ssh="$1" port="$2" hostname="$3" args=()

  if [[ "$ssh" == "" ]]; then
    exit 1
  elif [[ "$port" != "" ]]; then
    args+=(--ssh-port "$port")
  fi

  # TODO: Setup own private key?
  nixos-hardware "$ssh" "$port" "$hostname"
  nixos-anywhere --flake ".#$hostname" "${args[@]}" \
    --phases kexec,disko,install "$ssh"
}

function switch() {
  local ssh="$1" port="$2" hostname="$3" args=()

  if [[ "$ssh" != "" ]]; then
    args+=(--target-host "$ssh")
    if [[ "$port" != "" ]]; then
      export NIX_SSHOPTS="$NIX_SSHOPTS -p $port"
    fi
  fi

  nixos-hardware "$ssh" "$port" "$hostname"
  sudo nixos-rebuild switch --flake ".#$hostname" "${args[@]}"
  nixos-clean "$ssh" "$port" "$hostname"
}

function help() {
  echo "$0 setup|switch HOSTNAME [USER@HOST] [PORT]"
  echo "    setup   For a new build, wipes disk!"
  echo "    switch  Make a nixos-rebuild switch"
  echo "If nothing, the HOSTNAME will be \"$(hostname)\""
  return 1
}

function main() {
  local op=help ssh port hostname args=("$@")
  IFS=" " read -r op hostname ssh port <<<"$*"

  $op "${ssh:-}" "${port:-}" "${hostname:-"$(hostname)"}"
  if [[ -x "asterisk/setup.sh" ]]; then
    chmod -R g-rw,o-rw asterisk
    asterisk/setup.sh "${args[@]}"
  fi
}

cd "$(dirname "${BASH_SOURCE[0]}")"
main "$@"
