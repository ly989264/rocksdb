#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODE="all"
BUILD_DIR="build-minikv"
BUILD_TYPE="Debug"
JOBS="${JOBS:-}"

usage() {
  cat <<'EOF'
Usage:
  build_tools/build_linux.sh [--mode rocksdb|minikv|all] [--build-dir DIR] [--build-type TYPE] [--jobs N]

Modes:
  rocksdb  Configure the shared build directory and build the RocksDB shared library target.
  minikv   Build minikv targets in the existing configured directory. If the directory
           does not exist yet, it will be configured first. This mode assumes RocksDB
           has already been built, but will still build any missing prerequisite targets.
  all      Configure and build both RocksDB and minikv targets.

Outputs:
  - compile_commands.json
  - minikv/compile_commands.json
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode)
      MODE="$2"
      shift 2
      ;;
    --build-dir)
      BUILD_DIR="$2"
      shift 2
      ;;
    --build-type)
      BUILD_TYPE="$2"
      shift 2
      ;;
    --jobs)
      JOBS="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

case "${MODE}" in
  rocksdb|minikv|all)
    ;;
  *)
    echo "invalid mode: ${MODE}" >&2
    usage >&2
    exit 1
    ;;
esac

if [[ -z "${JOBS}" ]]; then
  if command -v nproc >/dev/null 2>&1; then
    JOBS="$(nproc)"
  else
    JOBS="$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 8)"
  fi
fi

ensure_compiledb() {
  if command -v compiledb >/dev/null 2>&1; then
    return 0
  fi
  if ! command -v python3 >/dev/null 2>&1; then
    echo "python3 not found; cannot install compiledb" >&2
    exit 1
  fi

  if ! python3 -m pip --version >/dev/null 2>&1; then
    python3 -m ensurepip --user
  fi

  python3 -m pip install --user compiledb
  export PATH="${PATH}:${HOME}/.local/bin:/root/.local/bin"

  if ! command -v compiledb >/dev/null 2>&1; then
    echo "compiledb installation succeeded but command is still unavailable" >&2
    exit 1
  fi
}

configure_build() {
  cmake -S "${REPO_ROOT}" -B "${REPO_ROOT}/${BUILD_DIR}" \
    -DCMAKE_BUILD_TYPE="${BUILD_TYPE}" \
    -DWITH_MINIKV=ON \
    -DWITH_TESTS=ON \
    -DWITH_GFLAGS=OFF \
    -DWITH_LIBURING=OFF \
    -DWITH_SNAPPY=OFF \
    -DWITH_LZ4=OFF \
    -DWITH_ZLIB=OFF \
    -DWITH_ZSTD=OFF \
    -DWITH_BZ2=OFF \
    -DWITH_JEMALLOC=OFF
}

build_targets() {
  local targets=("$@")
  cmake --build "${REPO_ROOT}/${BUILD_DIR}" --parallel "${JOBS}" --target "${targets[@]}"
}

generate_commands() {
  local targets=("$@")
  JOBS="${JOBS}" "${REPO_ROOT}/build_tools/generate_compile_commands.sh" "${BUILD_DIR}" "${targets[@]}"
}

cd "${REPO_ROOT}"
export PATH="${PATH}:${HOME}/.local/bin:/root/.local/bin"

if [[ ! -f "${REPO_ROOT}/${BUILD_DIR}/Makefile" ]]; then
  configure_build
elif [[ "${MODE}" == "all" || "${MODE}" == "rocksdb" ]]; then
  configure_build
fi

ensure_compiledb

ROCKSDB_TARGETS=(rocksdb-shared)
MINIKV_TARGETS=(
  minikv_server
  minikv_cmd_test
  minikv_hash_test
  minikv_server_test
  minikv_worker_test
)

case "${MODE}" in
  rocksdb)
    build_targets "${ROCKSDB_TARGETS[@]}"
    generate_commands "${ROCKSDB_TARGETS[@]}" "${MINIKV_TARGETS[@]}"
    ;;
  minikv)
    build_targets "${MINIKV_TARGETS[@]}"
    generate_commands "${ROCKSDB_TARGETS[@]}" "${MINIKV_TARGETS[@]}"
    ;;
  all)
    build_targets "${ROCKSDB_TARGETS[@]}" "${MINIKV_TARGETS[@]}"
    generate_commands "${ROCKSDB_TARGETS[@]}" "${MINIKV_TARGETS[@]}"
    ;;
esac

echo "build mode: ${MODE}"
echo "build dir: ${REPO_ROOT}/${BUILD_DIR}"
echo "compile database: ${REPO_ROOT}/compile_commands.json"
echo "minikv compile database: ${REPO_ROOT}/minikv/compile_commands.json"
