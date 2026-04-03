#!/usr/bin/env bash
set -euo pipefail

WORKSPACE_DIR="${1:-/work}"
MANIFEST_PATH="${2:-/zmk-config/config/west.yml}"
WANT_UPDATE="${3:-0}"
PROJECT_FILTER="${4:-}"
FETCH_OPT="${5:-}"
CHECK_BUILD_DEPS="${6:-1}"

run_west_update() {
	local -a cmd=(west update)
	if [[ -n "${FETCH_OPT}" ]]; then
		cmd+=("${FETCH_OPT}")
	fi
	"${cmd[@]}"
}

mkdir -p "${WORKSPACE_DIR}"
cd "${WORKSPACE_DIR}"

mkdir -p manifest-config
manifest_copy="manifest-config/west.yml"
manifest_changed=0

if [[ ! -f "${manifest_copy}" ]] || ! cmp -s "${MANIFEST_PATH}" "${manifest_copy}"; then
	cp "${MANIFEST_PATH}" "${manifest_copy}"
	manifest_changed=1
fi

needs_update=0

if [[ ! -d .west ]]; then
	west init -l manifest-config
	if [[ -n "${PROJECT_FILTER}" ]]; then
		west config --local manifest.project-filter "${PROJECT_FILTER}"
	fi
	needs_update=1
fi

if [[ "${manifest_changed}" == "1" ]]; then
	needs_update=1
fi

if [[ "${CHECK_BUILD_DEPS}" == "1" ]]; then
	if [[ ! -d zmk || ! -d zephyr ]]; then
		needs_update=1
	fi
fi

if [[ "${WANT_UPDATE}" == "1" ]]; then
	needs_update=1
fi

if [[ "${needs_update}" == "1" ]]; then
	run_west_update
fi
