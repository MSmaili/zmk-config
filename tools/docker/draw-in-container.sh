#!/usr/bin/env bash
set -euo pipefail

KEYMAPS_CSV="${1:-}"
WANT_UPDATE="${2:-0}"
CONFIG_PATH="${3:-/zmk-config/tools/keymap-drawer/config.yaml}"
OUTPUT_DIR="${4:-/zmk-config/tools/keymap-drawer}"

if [[ -z "${KEYMAPS_CSV}" ]]; then
	echo "No keymaps were provided." >&2
	exit 1
fi

export HOME="/work/home"
mkdir -p "${HOME}"

bash /zmk-config/tools/docker/bootstrap-workspace.sh \
	/work \
	/zmk-config/config/west.yml \
	"${WANT_UPDATE}" \
	" -zmk,-zephyr" \
	"--fetch-opt=--filter=tree:0" \
	"0"

IFS=',' read -r -a keymaps <<<"${KEYMAPS_CSV}"
for keymap_path in "${keymaps[@]}"; do
	keyboard="$(basename "${keymap_path}" .keymap)"
	echo "==> Drawing ${keyboard}"
	keymap -c "${CONFIG_PATH}" parse -z "/zmk-config/${keymap_path}" >"${OUTPUT_DIR}/${keyboard}.yaml"
	keymap -c "${CONFIG_PATH}" draw "${OUTPUT_DIR}/${keyboard}.yaml" >"${OUTPUT_DIR}/${keyboard}.svg"
done
