#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

IMAGE="${ZMK_DRAW_IMAGE:-zmk-local-keymap-drawer:0.23.0}"
WORKSPACE_VOLUME="${ZMK_WORKSPACE_VOLUME:-zmk-draw-cache}"
CONFIG_PATH="/zmk-config/tools/keymap-drawer/config.yaml"
OUTPUT_DIR="/zmk-config/tools/keymap-drawer"
CONTAINER_DRAW_SCRIPT="/zmk-config/tools/docker/draw-in-container.sh"

# shellcheck source=tools/lib/docker-common.sh
source "${REPO_ROOT}/tools/lib/docker-common.sh"

build_draw_image_if_missing() {
	if [[ -n "${ZMK_DRAW_IMAGE:-}" ]]; then
		return
	fi

	if docker image inspect "${IMAGE}" >/dev/null 2>&1; then
		return
	fi

	echo "Building local keymap-drawer image: ${IMAGE}"
	docker build \
		-t "${IMAGE}" \
		-f "${REPO_ROOT}/tools/docker/Dockerfile.keymap-drawer" \
		"${REPO_ROOT}"
}

print_usage() {
	cat <<'EOF'
Usage: tools/draw-keymaps-local.sh [keyboard...]

Parse and draw keymaps locally (YAML + SVG) using Docker.

Arguments:
  keyboard      Keyboard name (e.g. sweep, urchin) or path (config/urchin.keymap)

Examples:
  tools/draw-keymaps-local.sh
  tools/draw-keymaps-local.sh sweep
  tools/draw-keymaps-local.sh urchin cradio
  tools/draw-keymaps-local.sh forager

Outputs:
  tools/keymap-drawer/<keyboard>.yaml
  tools/keymap-drawer/<keyboard>.svg
EOF
}

declare -a keymap_args=()

while [[ $# -gt 0 ]]; do
	case "$1" in
	-h | --help)
		print_usage
		exit 0
		;;
	*)
		keymap_args+=("$1")
		;;
	esac
	shift
done

declare -a available_keymaps=()
while IFS= read -r path; do
	available_keymaps+=("${path}")
done < <(
	cd "${REPO_ROOT}"
	for f in config/*.keymap; do
		if [[ -e "${f}" ]]; then
			printf '%s\n' "${f}"
		fi
	done
)
declare -a selected_paths=()
if [[ ${#keymap_args[@]} -eq 0 ]]; then
	selected_paths=("${available_keymaps[@]}")
else
	for item in "${keymap_args[@]}"; do
		if [[ "${item}" == "sweep" ]]; then
			item="cradio"
		fi

		if [[ -f "${REPO_ROOT}/${item}" ]]; then
			selected_paths+=("${item}")
		elif [[ -f "${REPO_ROOT}/config/${item}.keymap" ]]; then
			selected_paths+=("config/${item}.keymap")
		else
			echo "Keymap not found: ${item}" >&2
			exit 1
		fi
	done
fi

if [[ ${#selected_paths[@]} -eq 0 ]]; then
	echo "No keymaps found in config/." >&2
	exit 1
fi

ensure_docker
build_draw_image_if_missing

keymaps_csv="$(
	IFS=,
	echo "${selected_paths[*]}"
)"

docker run --rm \
	-v "${REPO_ROOT}:/zmk-config" \
	-v "${WORKSPACE_VOLUME}:/work" \
	"${IMAGE}" \
	/bin/bash "${CONTAINER_DRAW_SCRIPT}" "${keymaps_csv}" "0" "${CONFIG_PATH}" "${OUTPUT_DIR}"

echo "Done. Generated files are in tools/keymap-drawer"
for keymap_path in "${selected_paths[@]}"; do
	keyboard="$(basename "${keymap_path}" .keymap)"
	echo "- tools/keymap-drawer/${keyboard}.yaml"
	echo "- tools/keymap-drawer/${keyboard}.svg"
done
