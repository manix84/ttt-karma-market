#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="${GLUALINT_VERSION:-1.29.0}"
TOOLS_DIR="${ROOT_DIR}/.tools/glualint/${VERSION}"
BIN_DIR="${TOOLS_DIR}/bin"

mkdir -p "${BIN_DIR}"

if [[ -x "${BIN_DIR}/glualint" || -x "${BIN_DIR}/glualint.exe" ]]; then
  echo "glualint ${VERSION} already installed in ${BIN_DIR}"
  exit 0
fi

platform="$(uname -s)"
arch="$(uname -m)"

case "${platform}:${arch}" in
  Linux:x86_64)
    asset="glualint-${VERSION}-x86_64-linux.zip"
    ;;
  Linux:aarch64|Linux:arm64)
    asset="glualint-${VERSION}-aarch64-linux.zip"
    ;;
  Darwin:x86_64)
    asset="glualint-${VERSION}-OSX-x86_64.tar.gz"
    ;;
  Darwin:arm64)
    asset="glualint-${VERSION}-OSX-x86_64.tar.gz"
    echo "No native macOS arm64 glualint asset exists for ${VERSION}; using the x86_64 build. Rosetta may be required." >&2
    ;;
  MINGW*:*|MSYS*:*|CYGWIN*:*)
    asset="glualint-${VERSION}-Windows.zip"
    ;;
  *)
    echo "Unsupported platform for glualint install: ${platform} ${arch}" >&2
    exit 1
    ;;
esac

url="https://github.com/FPtje/GLuaFixer/releases/download/${VERSION}/${asset}"
archive="${TOOLS_DIR}/${asset}"

echo "Downloading ${url}"
curl -L --fail --show-error --silent "${url}" -o "${archive}"

case "${asset}" in
  *.tar.gz)
    tar -xzf "${archive}" -C "${BIN_DIR}"
    ;;
  *.zip)
    unzip -q "${archive}" -d "${BIN_DIR}"
    ;;
esac

chmod +x "${BIN_DIR}/glualint" 2>/dev/null || true

echo "Installed glualint ${VERSION} in ${BIN_DIR}"
