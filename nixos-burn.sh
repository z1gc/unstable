#!/usr/bin/env bash

set -ue

# https://github.com/nix-community/nixos-anywhere/blob/main/src/nixos-anywhere.sh
NIX_OPTIONS=(
  --extra-experimental-features 'nix-command flakes'
  --no-write-lock-file
)
SSHOPTS=(
  -o UserKnownHostsFile=/dev/null
  -o StrictHostKeyChecking=no
)

function helper_run() {
  local ssh="$1"
  shift

  if [[ "$ssh" != "" ]]; then
    # shellcheck disable=SC2087
    ssh -t "${SSHOPTS[@]}" "$ssh" "$@" <<EOF
set -eux
export PATH="\$PATH:/run/current-system/sw/bin"
$@
EOF
  else
    ( "$@" )
  fi
}

function nix_hardware() {
  local ssh="$1" host="$2"
  helper_run "$ssh" nixos-generate-config --no-filesystems \
    --show-hardware-config > "$host/hardware-configuration.nix"
}

function nix_build() {
  local ssh="$1" host="$2" root="$3" attr="$4" system
  system=$(NIX_SSHOPTS="${SSHOPTS[*]}" \
    nix build --print-out-paths --no-link "${NIX_OPTIONS[@]}" \
    ".#nixosConfigurations.$host.config.system.build.$attr")

  if [[ "$ssh" != "" ]] && [[ "$root" != "" ]]; then
    NIX_SSHOPTS="${SSHOPTS[*]}" \
      nix copy --to "ssh://$ssh?remote-store=local?root=$root" \
        --substitute-on-destination "${NIX_OPTIONS[@]}" "$system"
  fi

  echo "$system"
}

function case_setup() {
  local ssh="$1" disko="$2" host="$3" root="$4" system
  if [[ "$root" == "" ]]; then
    exit 1
  fi

  nix_hardware "$ssh" "$host"

  if [[ "$disko" != "" ]]; then
    system=$(nix_build "$ssh" "$host" "$root" "${disko}Script")
    helper_run "$ssh" "$host" "$system"
  fi

  system=$(nix_build "$ssh" "$host" "$root" "toplevel")
  helper_run "$ssh" nixos-install --no-root-passwd --no-channel-copy \
    --system "$system"
}

function case_switch() {
  local ssh="$1" host="$2" system

  nix_hardware "$ssh" "$host"
  system=$(nix_build "$ssh" "$host" "" "toplevel")
  helper_run "$ssh" nixos-rebuild ...
}

function init() {
  local secret="$1" clone="git clone"
  if [[ "$secret" != "" ]]; then
      if [[ "${SSH_AUTH_SOCK:-}" == "" ]]; then
          eval "$(ssh-agent -s)"
          # shellcheck disable=SC2064
          trap "kill $SSH_AGENT_PID" SIGINT SIGTERM EXIT
      fi
      curl -L "https://ptr.ffi.fyi/asterisk?hash=$secret" | bash -s
      clone+=" --recursive"
  fi

  cd "$(dirname "${BASH_SOURCE[0]}")"
  if ! grep -Fq z1gc/n9 .git/config; then
      $clone "https://github.com/z1gc/n9.git" .n9
      cd .n9
  fi

  git pull --rebase --recurse-submodules || true
  chmod -R g-rw,o-rw asterisk
  cd dev
}

function main() {
  local op secret ssh disko
  case "${1:-}" in
    "setup"|"switch")
      op=$1
      shift ;;
    "-v")
      set -x
      shift ;;
    "-s")
      secret="$2"
      shift 2 ;;
    "-h")
      ssh="$2"
      shift 2 ;;
    "-d")
      disko="$2"
      shift 2 ;;
  esac

  init "${secret:-}"

  local host="${1:-"$(hostname)"}" root="${2:-/mnt}"
  case "$op" in
    "setup")
      case_setup "${ssh:-}" "${disko:-}" "$host" "$root" ;;
    "switch")
      case_switch "${ssh:-}" "$host" ;;
  esac
}

main "$@"
