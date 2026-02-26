#!/usr/bin/env bash

if [[ -z $toolchainfile_linux ]]; then
    echo "This build script must be run in the nix development shell, which makes the toolchain files available as environment variables."
    echo "  cd nhcrossbuild"
    echo "  nix develop"
    echo "Then run this script."
    exit 1
fi

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

build() {
    local platform="$1"
    local toolchain="$2"

    local install_dir="$SCRIPT_DIR/assets/$platform"
    local build_dir="$SCRIPT_DIR/build/$platform"

    echo "==> Building for $platform (build dir: $build_dir, install dir: $install_dir)"

    cmake -G "Ninja" -S "$SCRIPT_DIR" -B "$build_dir" \
        -DCMAKE_TOOLCHAIN_FILE="$toolchain" \
        -DCMAKE_INSTALL_PREFIX="$install_dir" \
        -DCMAKE_BUILD_TYPE=Release

    cmake --build "$build_dir"
    cmake --install "$build_dir"

    echo "==> Done: $platform"
}

build linux        "$toolchainfile_linux"
build mac          "$toolchainfile_macos_dual"
build winx64       "$toolchainfile_windows_mingw_x86_64"
build winarm       "$toolchainfile_windows_mingw_aarch64"
