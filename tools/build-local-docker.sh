#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# shellcheck source=tools/lib/docker-common.sh
source "${REPO_ROOT}/tools/lib/docker-common.sh"

IMAGE="zmkfirmware/zmk-build-arm:stable"
WORKSPACE_VOLUME="zmk-workspace-cache"
OUT_DIR="${REPO_ROOT}/build/local"
CONTAINER_SCRIPT="/zmk-config/tools/docker/build-profile-in-container.sh"

keyboard="${1:-}"
mode_flag="${2:-}"

if [[ -z "${keyboard}" ]]; then
	echo "Usage: tools/build-local-docker.sh <keyboard> [--dongle]" >&2
	exit 1
fi

if [[ $# -gt 2 ]]; then
	echo "Usage: tools/build-local-docker.sh <keyboard> [--dongle]" >&2
	exit 1
fi

use_dongle=0
if [[ -n "${mode_flag}" ]]; then
	if [[ "${mode_flag}" != "--dongle" ]]; then
		echo "Unknown arg: ${mode_flag}" >&2
		exit 1
	fi
	use_dongle=1
fi

if [[ ! -f "${REPO_ROOT}/build.yaml" ]]; then
	echo "Build matrix file does not exist: ${REPO_ROOT}/build.yaml" >&2
	exit 1
fi

mkdir -p "${OUT_DIR}"
ensure_docker

docker run --rm \
	-v "${REPO_ROOT}:/zmk-config:ro" \
	-v "${WORKSPACE_VOLUME}:/work" \
	-v "${OUT_DIR}:/out" \
	"${IMAGE}" \
	/bin/bash "${CONTAINER_SCRIPT}" "${keyboard}" "${use_dongle}"

if [[ "${use_dongle}" == "1" ]]; then
	echo "Done. Artifacts are in ${OUT_DIR}"
	echo "- build/local/${keyboard}_left_peripheral.uf2"
	echo "- build/local/${keyboard}_right.uf2"
	echo "- build/local/${keyboard}_dongle.uf2"
else
	echo "Done. Artifacts are in ${OUT_DIR}"
	echo "- build/local/${keyboard}_right.uf2"
	echo "- build/local/${keyboard}_left_central.uf2"
fi
