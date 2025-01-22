ifneq (${USER},root)
$(error Run as root or sudo)
endif

export HOSTNAME ?= $(shell hostname)

ifneq (${SUDO_USER},)
RUNAS = su "${SUDO_USER}"
else
RUNAS = su "$(shell stat -c %U .git)"
endif

# The make will treat the result/outpu of `$(...)` as a receipt, therefore we
# need to clear out the stdout.
$(shell ${RUNAS} -c "git pull --rebase --recurse-submodules" 1>&2)
$(shell chmod -R g-rw,o-rw asterisk 1>&2)

FLAKE = ./octothorp/${HOSTNAME}
HWCONF = octothorp/${HOSTNAME}/hardware-configuration.nix

${HWCONF}:
	nixos-generate-config --no-filesystems --show-hardware-config > "$@"

setup: ${HWCONF}
	grep -Eq 'VARIANT_ID="?installer"?' /etc/os-release
	nix build --extra-experimental-features "nix-command flakes" --no-link \
		--print-out-paths --no-write-lock-file \
		"${FLAKE}#nixosConfiguration.${HOSTNAME}.config.system.build.diskoScript" \
		| bash -s
	nixos-install --no-root-password --no-channel-copy --flake \
		"${FLAKE}#${HOSTNAME}"
	if test -f asterisk/Makefile; then ${MAKE} -C asterisk setup; fi

garbage:
	nix-collect-garbage --delete-older-than 2d
	${RUNAS} -c "nix-collect-garbage --delete-older-than 2d"

switch: ${HWCONF} garbage
	rm -f "octothorp/${HOSTNAME}/flake.lock"
	nixos-rebuild switch --show-trace --flake "${FLAKE}#${HOSTNAME}"
	if test -f asterisk/Makefile; then ${MAKE} -C asterisk switch; fi

.PHONY: setup garbage switch
.DEFAULT_GOAL = switch
