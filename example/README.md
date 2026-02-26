# HelloWorld Example

This is a simple cross-platform GUI application using [wxWidgets](https://www.wxwidgets.org/) to demonstrate the capabilities of the [nhcrossbuild](../README.md) toolchain.

## Files

- [main.cpp](main.cpp): A minimal wxWidgets application that displays a "Hello World" window.
- [CMakeLists.txt](CMakeLists.txt): The CMake project file. It uses `FetchContent` to download and build wxWidgets from source as part of the build process.
- [build.sh](build.sh): A script to build the application for all supported platforms (Linux, macOS, Windows x86_64, and Windows ARM64).
- [run_on_nix.sh](run_on_nix.sh): A helper script to run the generated Linux binary on a Nix-based system using a [FHS environment](https://nixos.wiki/wiki/FHS_Environments). Not needed on other Linux distributions.

## Building the Example

The build process must be performed within the Nix development environment provided by this project.

1.  **Enter the development environment:**

    ```bash
    cd ..
    nix develop
    ```

2.  **Run the build script:**

    ```bash
    cd example
    ./build.sh
    ```

The script will invoke CMake for each target platform, setting -DCMAKE_TOOLCHAIN_FILE for the target platform. The resulting binaries and bundles will be placed into the `assets/` directory.

## Running the Application

### Linux

The resulting linux binary can be run directly on most linux distributions. Running on nixos requires a wrapper (see run_on_nix.sh).

### macOS

The build process creates a universal (x86_64 and arm64) macOS bundle: `assets/mac/HelloWorld.app`. 

The application is signed with an ad-hoc signature. Run it by right clicking and selecting "Open", or by running `xattr -cr assets/mac/HelloWorld.app` in the terminal to remove the quarantine attribute. The rcodesign tool can be used to sign with an apple developer certificate, and also to notarize the app for distribution.

### Windows

The build process produces separate executables for x86_64 and ARM64 in `assets/winx64/HelloWorld.exe` and `assets/winarm/HelloWorld.exe`. These can be run as-is on any Windows 10 or later system.
