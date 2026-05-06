#!/usr/bin/env bash
set -euo pipefail

keyboard="${1:-}"
use_dongle="${2:-0}"
build_matrix_path="/zmk-config/build.yaml"

if [[ -z "${keyboard}" ]]; then
    echo "Keyboard is required." >&2
    exit 1
fi

if [[ ! -f "${build_matrix_path}" ]]; then
    echo "Build matrix file not found: ${build_matrix_path}" >&2
    exit 1
fi

cd /work

if [[ ! -d .west ]]; then
    mkdir -p .west
    printf '[manifest]\npath = config\nfile = west.yml\n' > .west/config
    ln -sfn /zmk-config/config config
fi

# Always refresh the west workspace so newly added modules in config/west.yml
# are fetched into the cached Docker volume as well.
west update

right_artifact="${keyboard}_right"
if [[ "${use_dongle}" == "1" ]]; then
    target_artifacts=(
        "${keyboard}_left_peripheral"
        "${right_artifact}"
        "${keyboard}_dongle"
    )
else
    target_artifacts=(
        "${right_artifact}"
        "${keyboard}_left_central"
    )
fi

mapfile -t artifact_specs < <(
    python3 - "${build_matrix_path}" "${target_artifacts[@]}" <<'PY'
import sys

try:
    import yaml
except Exception:
    print("ERROR: Missing PyYAML in build container", file=sys.stderr)
    sys.exit(2)

matrix_path = sys.argv[1]
targets = sys.argv[2:]

with open(matrix_path, "r", encoding="utf-8") as f:
    data = yaml.safe_load(f) or {}

by_name = {}
for row in data.get("include", []):
    if isinstance(row, dict):
        name = row.get("artifact-name")
        if name:
            by_name[name] = row

for name in targets:
    row = by_name.get(name)
    if row is None:
        print(f"ERROR: Artifact '{name}' not found in {matrix_path}", file=sys.stderr)
        sys.exit(1)

    board = row.get("board", "")
    shield = row.get("shield", "")
    snippet = row.get("snippet", "")
    cmake_args = row.get("cmake-args", "")
    print("\x1f".join([name, board, shield, snippet, cmake_args]))
PY
)

if [[ "${#artifact_specs[@]}" -ne "${#target_artifacts[@]}" ]]; then
    echo "Failed to resolve build specs for ${keyboard}" >&2
    exit 1
fi

mkdir -p /out

for spec in "${artifact_specs[@]}"; do
    IFS=$'\x1f' read -r artifact_name board shield snippet cmake_args_raw <<<"${spec}"

    if [[ -z "${board}" || -z "${shield}" ]]; then
        echo "Invalid build matrix entry for ${artifact_name}: board/shield is missing" >&2
        exit 1
    fi

    build_dir="/work/build/${artifact_name}"
    west_extra_args=()
    cmake_args=(
        -DSHIELD="${shield}"
        -DZMK_CONFIG=/zmk-config/config
        -DZMK_EXTRA_MODULES=/zmk-config
        -DZEPHYR_BASE=/work/zephyr
        -DZephyr_DIR=/work/zephyr/share/zephyr-package/cmake
    )

    if [[ -n "${snippet}" ]]; then
        west_extra_args=(-S "${snippet}")
    fi

    if [[ -n "${cmake_args_raw}" ]]; then
        # shellcheck disable=SC2206
        extra_cmake_args=(${cmake_args_raw})
        cmake_args+=("${extra_cmake_args[@]}")
    fi

    echo "==> Building ${artifact_name}"
    rm -rf "${build_dir}"
    west build -d "${build_dir}" -b "${board}" "${west_extra_args[@]}" /work/zmk/app -- "${cmake_args[@]}"

    if [[ -f "${build_dir}/zephyr/zmk.uf2" ]]; then
        cp "${build_dir}/zephyr/zmk.uf2" "/out/${artifact_name}.uf2"
    fi
done
