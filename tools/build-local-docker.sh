#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# shellcheck source=tools/lib/docker-common.sh
source "${REPO_ROOT}/tools/lib/docker-common.sh"

IMAGE="${ZMK_BUILD_IMAGE:-zmkfirmware/zmk-build-arm:stable}"
WORKSPACE_VOLUME="${ZMK_WORKSPACE_VOLUME:-zmk-workspace-cache}"
OUT_DIR="${REPO_ROOT}/build/local"
CONTAINER_SCRIPT="/zmk-config/tools/docker/build-profile-in-container.sh"

print_usage() {
	cat <<'EOF'
Usage: tools/build-local-docker.sh <keyboard> [--dongle] [--matrix <path>]

Builds three artifacts for one keyboard by reading entries from build.yaml:
  - <keyboard>_left_peripheral
  - <keyboard>_right
  - <keyboard>_left_central (default) or <keyboard>_dongle (--dongle)

Keyboard values are inferred from artifact names in the matrix.
Example: for artifact-name "forager_right", keyboard is "forager".

Examples:
  tools/build-local-docker.sh urchin
  tools/build-local-docker.sh urchin --dongle
  tools/build-local-docker.sh forager --matrix build.yaml

Artifacts:
  build/local/<keyboard>_left_peripheral.uf2
  build/local/<keyboard>_right.uf2
  build/local/<keyboard>_left_central.uf2 or build/local/<keyboard>_dongle.uf2
EOF
}

keyboard=""
use_dongle=0
matrix_path="${BUILD_MATRIX_PATH:-build.yaml}"

while [[ $# -gt 0 ]]; do
	case "$1" in
	--dongle)
		use_dongle=1
		;;
	--matrix)
		if [[ $# -lt 2 ]]; then
			echo "--matrix requires a path argument." >&2
			exit 1
		fi
		matrix_path="$2"
		shift
		;;
	-h | --help)
		print_usage
		exit 0
		;;
	*)
		if [[ -n "${keyboard}" ]]; then
			echo "Only one keyboard can be provided. Unknown arg: $1" >&2
			exit 1
		fi
		keyboard="$1"
		;;
	esac
	shift
done

if [[ -z "${keyboard}" ]]; then
	echo "Keyboard is required." >&2
	print_usage
	exit 1
fi

if [[ "${matrix_path}" = /* ]]; then
	host_matrix_path="${matrix_path}"
	container_matrix_path="${matrix_path}"
else
	host_matrix_path="${REPO_ROOT}/${matrix_path}"
	container_matrix_path="/zmk-config/${matrix_path}"
fi

if [[ ! -f "${host_matrix_path}" ]]; then
	echo "Build matrix file does not exist: ${host_matrix_path}" >&2
	exit 1
fi

mkdir -p "${OUT_DIR}"
ensure_docker

docker run --rm \
	-v "${REPO_ROOT}:/zmk-config:ro" \
	-v "${WORKSPACE_VOLUME}:/work" \
	-v "${OUT_DIR}:/out" \
	"${IMAGE}" \
	/bin/bash "${CONTAINER_SCRIPT}" "${keyboard}" "${use_dongle}" "${container_matrix_path}"

if [[ "${use_dongle}" == "1" ]]; then
	third_name="${keyboard}_dongle"
else
	third_name="${keyboard}_left_central"
fi

echo "Done. Artifacts are in ${OUT_DIR}"
echo "- build/local/${keyboard}_left_peripheral.uf2"
echo "- build/local/${keyboard}_right.uf2"
echo "- build/local/${third_name}.uf2"
