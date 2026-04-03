#!/usr/bin/env bash
set -euo pipefail

keyboard="${1:-}"
use_dongle="${2:-0}"
build_matrix_path="${3:-/zmk-config/build.yaml}"

if [[ -z "${keyboard}" ]]; then
	echo "Keyboard is required." >&2
	exit 1
fi

if [[ ! -f "${build_matrix_path}" ]]; then
	echo "Build matrix file not found: ${build_matrix_path}" >&2
	exit 1
fi

bash /zmk-config/tools/docker/bootstrap-workspace.sh \
	/work \
	/zmk-config/config/west.yml \
	0 \
	"" \
	"" \
	1

cd /work

spec_board=""
spec_shield=""
spec_snippet=""
spec_cmake_args=""

load_artifact_spec() {
	local artifact_name="$1"
	local -a spec

	mapfile -t spec < <(
		python3 - "${build_matrix_path}" "${artifact_name}" <<'PY'
import sys

try:
    import yaml
except Exception:
    print("ERROR: Missing PyYAML in build container", file=sys.stderr)
    sys.exit(2)

matrix_path = sys.argv[1]
artifact_name = sys.argv[2]

with open(matrix_path, "r", encoding="utf-8") as f:
    data = yaml.safe_load(f) or {}

for row in data.get("include", []):
    if isinstance(row, dict) and row.get("artifact-name") == artifact_name:
        print(row.get("board", ""))
        print(row.get("shield", ""))
        print(row.get("snippet", ""))
        print(row.get("cmake-args", ""))
        sys.exit(0)

print(f"ERROR: Artifact '{artifact_name}' not found in {matrix_path}", file=sys.stderr)
sys.exit(1)
PY
	)

	if [[ "${#spec[@]}" -ne 4 ]]; then
		echo "Failed to parse build matrix entry for ${artifact_name}" >&2
		exit 1
	fi

	spec_board="${spec[0]}"
	spec_shield="${spec[1]}"
	spec_snippet="${spec[2]}"
	spec_cmake_args="${spec[3]}"

	if [[ -z "${spec_board}" || -z "${spec_shield}" ]]; then
		echo "Invalid build matrix entry for ${artifact_name}: board/shield is missing" >&2
		exit 1
	fi
}

build_one() {
	local name="$1"
	local board="$2"
	local shield="$3"
	local snippet="$4"
	local cmake_args_raw="$5"
	local build_dir="/work/build/${name}"
	local -a west_extra_args=()
	local -a cmake_args=(
		-DSHIELD="${shield}"
		-DZMK_CONFIG=/zmk-config/config
		-DZMK_EXTRA_MODULES=/zmk-config
		-DZEPHYR_BASE=/work/zephyr
		-DZephyr_DIR=/work/zephyr/share/zephyr-package/cmake
	)

	if [[ -n "${snippet}" ]]; then
		west_extra_args+=(-S "${snippet}")
	fi

	if [[ -n "${cmake_args_raw}" ]]; then
		# shellcheck disable=SC2206
		local -a parsed_extra_args=(${cmake_args_raw})
		cmake_args+=("${parsed_extra_args[@]}")
	fi

	echo "==> Building ${name}"
	echo "    board: ${board}"
	echo "    shield: ${shield}"
	if [[ -n "${snippet}" ]]; then
		echo "    snippet: ${snippet}"
	fi
	if [[ -n "${cmake_args_raw}" ]]; then
		echo "    cmake-args: ${cmake_args_raw}"
	fi
	rm -rf "${build_dir}"
	west build -d "${build_dir}" -b "${board}" "${west_extra_args[@]}" /work/zmk/app -- "${cmake_args[@]}"

	mkdir -p /out
	if [[ -f "${build_dir}/zephyr/zmk.uf2" ]]; then
		cp "${build_dir}/zephyr/zmk.uf2" "/out/${name}.uf2"
	fi
	if [[ -f "${build_dir}/zephyr/zephyr.bin" ]]; then
		cp "${build_dir}/zephyr/zephyr.bin" "/out/${name}.bin"
	fi
	if [[ -f "${build_dir}/zephyr/zephyr.hex" ]]; then
		cp "${build_dir}/zephyr/zephyr.hex" "/out/${name}.hex"
	fi
}

left_artifact="${keyboard}_left_peripheral"
right_artifact="${keyboard}_right"

if [[ "${use_dongle}" == "1" ]]; then
	third_artifact="${keyboard}_dongle"
else
	third_artifact="${keyboard}_left_central"
fi

load_artifact_spec "${left_artifact}"
build_one "${left_artifact}" "${spec_board}" "${spec_shield}" "${spec_snippet}" "${spec_cmake_args}"

load_artifact_spec "${right_artifact}"
build_one "${right_artifact}" "${spec_board}" "${spec_shield}" "${spec_snippet}" "${spec_cmake_args}"

load_artifact_spec "${third_artifact}"
build_one "${third_artifact}" "${spec_board}" "${spec_shield}" "${spec_snippet}" "${spec_cmake_args}"
