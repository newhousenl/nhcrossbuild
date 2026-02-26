# nhcrossbuild

A cross-platform build system using CMake, Clang, and libc++.

When building a cross platform C++ application, we face several challenges: the standard toolchains on each platform are different: they use different compilers (msvc, gcc, clang) and different c++ standard libraries (libc++, libstdc++ and msvc's STL). 

On macOS the c++ standard library is a dylib, it's version is tied to the target macOS version. So if we want our application to run older macOS versions, we cannot use newer STL features.

On Linux, distributing binary applications is challenging: we cannot statically link against glibc, but dynamically linking against the system's glibc makes the executable incompatible with older linux distributions. Statically linking musl is an option for CLI tools, but not for GUI applications because we must dynamically link against GTK and other libraries which themselves depend on glibc. The usual advise is to 'build your app on an old linux distribution', but this is  cumberome. It also limits us to older compiler and c++ std library versions, lacking support for modern c++ features.

This project solves all these problems and provides a Nix-based development environment that simplifies cross-compiling for various platforms. For all platforms we have a modern clang compiler and we statically link against the same modern version of libc++. For linux, a sysroot is built from the debian 10 archives, providing the libraries our application is dynamically linked against.

By using nix we can build for all 3 platforms from any of them. You only need to pass the -DCMAKE_TOOLCHAIN_FILE option to CMake to target a specific platform.

## Battle tested in production
This build system is used to build [PTGui](https://ptgui.com/), a commercial panorama stitching software with over 25 years of development and a large user base.

## Supported Platforms

The build system can produce:
- **Linux**: x86_64 binary, linked against glibc version 2.28. This will run in modern glibc-based Linux distributions (Debian 10, fedora 34, Ubuntu 20.04, etc.)
- **macOS**: Fat bundle (Universal binaries), built against the macOS 10.15 SDK.
- **Windows**: separate x86_64 and ARM64 executables, built against the UCRT. The ucrt is included in Windows 10 and later, no need to worry about the MSVC redistributable or other dlls.

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

Note that the 3rd party components mentioned above are subject to their own respective licenses.
