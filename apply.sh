#!/usr/bin/env bash

set -ue

MACHINE="${1:-}"
ROOT="${2:-}"
ROOT="${ROOT%/}"

if [[ "$MACHINE" == "" ]]; then
    echo "$0 MACHINE [ROOT]"
    exit 1
fi

# To here, or to tmp (TODO: cleanup?):
manifest=nixos
cd "$(dirname "${BASH_SOURCE[0]}")"
if [[ ! -d .git ]]; then
    mkdir -p /tmp/unstable
    cd /tmp/unstable
    manifest=https://github.com/z1gc/unstable:nixos
fi

# Check comtrya:
if [[ ! -f comtrya ]]; then
    # shellcheck disable=SC2016
    curl -fsSL https://get.comtrya.dev | sed 's/$BINLOCATION/./g' | bash || true
    if ! ./comtrya version; then
        rm -f ./comtrya
        echo "wrong binary, please retry..."
        exit 1
    fi
fi

# Generate config:
cat > Comtrya.yaml <<EOF
variables:
    machine: "$MACHINE"
    root: "$ROOT"
EOF

# Apply!
sudo ./comtrya -v -d $manifest apply -m "$MACHINE"
