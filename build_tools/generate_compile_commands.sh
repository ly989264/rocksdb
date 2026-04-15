#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${1:-build-minikv}"
shift || true
JOBS="${JOBS:-8}"

if [[ $# -eq 0 ]]; then
  set -- minikv_server minikv_cmd_test minikv_hash_test \
    minikv_server_test minikv_worker_test
fi

if ! command -v compiledb >/dev/null 2>&1; then
  echo "compiledb not found in PATH" >&2
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 not found in PATH" >&2
  exit 1
fi

if [[ ! -f "${REPO_ROOT}/${BUILD_DIR}/Makefile" ]]; then
  echo "build directory ${REPO_ROOT}/${BUILD_DIR} is not configured" >&2
  exit 1
fi

cd "${REPO_ROOT}"

compiledb -n -f -o "${REPO_ROOT}/compile_commands.json" \
  make -C "${BUILD_DIR}" -j"${JOBS}" \
  "$@"

python3 - "${REPO_ROOT}/compile_commands.json" \
  "${REPO_ROOT}/minikv/compile_commands.json" <<'PY'
import json
import sys

src_path = sys.argv[1]
dst_path = sys.argv[2]

with open(src_path, "r", encoding="utf-8") as infile:
    entries = json.load(infile)

minikv_entries = [
    entry for entry in entries if "/minikv/" in entry.get("file", "")
]

with open(dst_path, "w", encoding="utf-8") as outfile:
    json.dump(minikv_entries, outfile, indent=2)
    outfile.write("\n")

print(f"wrote {len(entries)} entries to {src_path}")
print(f"wrote {len(minikv_entries)} entries to {dst_path}")
PY
