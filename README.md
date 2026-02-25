# nhcrossbuild

A cross-platform build system using CMake, Clang, and libc++.

This project provides a Nix-based development environment that simplifies cross-compiling for various platforms. Build for 3 platforms from a single host. Uses the same clang compiler on all platforms and link statically against the same modern version of libc++. You only need to pass the -DCMAKE_TOOLCHAIN_FILE option to CMake to build for a different platform.

## Supported Platforms

The build system can produce:
- **Linux**: x86_64 binary, linked against glibc version 2.28. This will generally run in most modern Linux distributions (Debian 10, fedora 34, Ubuntu 20.04, etc.)
- **macOS**: Fat bundle (Universal binaries)
- **Windows**: separate x86_64 and ARM64 executables

## Usage

This project uses the **Nix** package manager to provide a consistent development environment. If you don't have Nix yet, you can use it on:
- **NixOS** or **nix-darwin** (native)
- **Linux** (by installing the Nix tool in your existing distro)
- **Windows** (via **Nix-WSL**)

Enter the development environment:

```bash
cd nhcrossbuild
nix develop
```

Once inside the environment (a bash shell), you can build your own CMake project for any of the supported platforms by passing the appropriate CMake toolchain file:

```bash
cmake -DCMAKE_TOOLCHAIN_FILE=$toolchainfile_xxx ..
```

### Available Toolchain Files

- **Linux x86_64**: `$toolchainfile_linux`
- **macOS Fat Bundle**: `$toolchainfile_macos_dual`
- **macOS Current architecture only**: `$toolchainfile_macos_single`
- **Windows x86_64**: `$toolchainfile_windows_mingw_x86_64`
- **Windows ARM64**: `$toolchainfile_windows_mingw_aarch64`

## Acknowledgments and 3rd Party Components

This build system leverages several 3rd party projects to enable cross-platform functionality:

- **LLVM-project**: Provide the Clang compiler, LLD linker, and libc++ library.
- **tpoechtrager's macOS Tools**:
  - **[cctools-port](https://github.com/tpoechtrager/cctools-port)**: Port of Apple cctools and ld64.
  - **[apple-libtapi](https://github.com/tpoechtrager/apple-libtapi)**: Port of Apple's TAPI library.
- **Windows Support**:
  - **MinGW-w64**: Headers and runtime for Windows development.
- **Linux Support**:
  - **Debian 10 (Buster)**: Used for the base Linux sysroot to ensure compatibility.
- **macOS SDK**:
  - **[joseluisq/macos-sdks](https://github.com/joseluisq/macos-sdks)**: Provides the macOS SDK for cross-compilation.
- **Other Utilities**:
  - **[apple-codesign (rcodesign)](https://github.com/indygreg/apple-platform-rs)**: Used for macOS binary signing.

## License

This project is licensed under the **0BSD License (Zero-Clause BSD)** - see the [LICENSE](LICENSE) file for details. This license allows for commercial use, modification, and distribution without any attribution requirement.

**Note:** This license applies only to the build scripts and configuration files in this repository. The 3rd party components mentioned above are subject to their own respective licenses.
