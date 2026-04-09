#!/usr/bin/env bash
set -euo pipefail

KEYMAP_PATH="${1:-}"

if [[ -z "${KEYMAP_PATH}" ]]; then
    echo "No keymap was provided." >&2
    exit 1
fi

if [[ ! -f "/zmk-config/${KEYMAP_PATH}" ]]; then
    echo "Keymap not found: /zmk-config/${KEYMAP_PATH}" >&2
    exit 1
fi

export HOME="/work/home"
mkdir -p "${HOME}"

cd /work

if [[ ! -d .west ]]; then
    mkdir -p .west
    printf '[manifest]\npath = config\nfile = west.yml\n' > .west/config
    ln -sfn /zmk-config/config config
    west config --local -- manifest.project-filter "-zmk,-zephyr"
    west update --fetch-opt=--filter=tree:0
fi

keyboard="$(basename "${KEYMAP_PATH}" .keymap)"

echo "==> Drawing ${keyboard}"
keymap -c "/zmk-config/tools/keymap-drawer/config.yaml" parse -z "/zmk-config/${KEYMAP_PATH}" >"/zmk-config/tools/keymap-drawer/${keyboard}.yaml"
keymap -c "/zmk-config/tools/keymap-drawer/config.yaml" draw "/zmk-config/tools/keymap-drawer/${keyboard}.yaml" >"/zmk-config/tools/keymap-drawer/${keyboard}.svg"
