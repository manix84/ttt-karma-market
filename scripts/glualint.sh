#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="${GLUALINT_VERSION:-1.29.0}"
BIN_DIR="${ROOT_DIR}/.tools/glualint/${VERSION}/bin"

if [[ ! -x "${BIN_DIR}/glualint" && ! -x "${BIN_DIR}/glualint.exe" ]]; then
  "${ROOT_DIR}/scripts/install-glualint.sh"
fi

if [[ -x "${BIN_DIR}/glualint" ]]; then
  GLUALINT="${BIN_DIR}/glualint"
else
  GLUALINT="${BIN_DIR}/glualint.exe"
fi

if [[ "$#" -gt 0 ]]; then
  exec "${GLUALINT}" "$@"
fi

mapfile_args=()
while IFS= read -r file; do
  mapfile_args+=("${file}")
done < <(find "${ROOT_DIR}/lua" -type f -name '*.lua' | sort)

exec "${GLUALINT}" lint "${mapfile_args[@]}"
