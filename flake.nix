{
  nixConfig.bash-prompt-prefix = "nhcrossbuild>";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      makeDevShell =
        {
          system,
          #nixpkgs,
          extraToolchainContent ? "",
        }:
        let
          pkgs = import nixpkgs {
            inherit system;
            config = {
              allowUnfree = true;
              allowBroken = true; # nsis-3.11 is broken on Darwin
            };
          };
          extraContent = if extraToolchainContent == null then "" else extraToolchainContent;
          llvmversion = "21";
          llvmfullversion = "21.1.8";
          llvmhash = "sha256-pgd8g9Yfvp7abjCCKSmIn1smAROjqtfZaJkaUkBSKW0=";
          llvmPackagesToUse = pkgs."llvmPackages_${llvmversion}";

          llvmsrc = pkgs.fetchFromGitHub {
            owner = "llvm";
            repo = "llvm-project";
            rev = "llvmorg-${llvmfullversion}";
            hash = llvmhash;
          };

          toolchain_linux = pkgs.callPackage ./modules/linux-deb10-toolchain/default.nix {
            inherit
              llvmPackagesToUse
              llvmversion
              llvmsrc
              llvmfullversion
              ;
          };
          toolchain_macos = pkgs.callPackage ./modules/macos-toolchain/default.nix {
            inherit
              llvmPackagesToUse
              llvmversion
              llvmsrc
              llvmfullversion
              ;
          };
          toolchains_windows_mingw = {
            x86_64 = pkgs.callPackage ./modules/windows-mingw-toolchain/default.nix {
              target = "x86_64";
              inherit
                llvmPackagesToUse
                llvmversion
                llvmsrc
                llvmfullversion
                ;
            };
            aarch64 = pkgs.callPackage ./modules/windows-mingw-toolchain/default.nix {
              target = "aarch64";
              inherit
                llvmPackagesToUse
                llvmversion
                llvmsrc
                llvmfullversion
                ;
            };
          };
        in
        pkgs.stdenvNoCC.mkDerivation {
          name = "nhcrossbuild";
          phases = [ ];
          nativeBuildInputs =
            with pkgs;
            [
              # nasm
              # go
              # (perl.withPackages(ps: [ ps.PerlLanguageServer ps.ImageExifTool ]))

              python3
              cmake
              lldb
              llvmPackagesToUse.clang-tools
              ninja
              git
              less
              which
              pkg-config
              bashInteractive # needed for bash shell in vs code
            ]
            ++ toolchains_windows_mingw.x86_64.nativeBuildInputs
            ++ toolchain_macos.nativeBuildInputs
            ++ toolchain_linux.nativeBuildInputs
            ++ lib.optional (!stdenvNoCC.isDarwin) [
              # # for profiling:
              # valgrind
              # kdePackages.kcachegrind
              # pkgs.gperftools
              # graphviz  # required by pprof --web
              # llvmPackagesToUse.bintools  # for objdump # required by pprof-symbolize

              # # requirecd by gtk3:
              # libsysprof-capture
              # pcre2
              # libselinux
              # cacert
              # ocl-icd
              gtk3
              dbus
              glib
              util-linux
              libGLU

              libxkbcommon
              xorg.libX11.dev
              xorg.libX11
              xorg.libXcursor
              xorg.libXrandr
              xorg.libICE
              xorg.libSM
              xorg.libXext
              xorg.libXtst
              udev
              alsa-lib
              egl-wayland
              libGL
              eglexternalplatform
              gdk-pixbuf
              cairo
              harfbuzz
              pango
              atk
              wayland
              adwaita-icon-theme
            ];

          toolchainfile_macos_single = pkgs.writeText "mactoolchain_single.cmake" (
            toolchain_macos.toolchaintxt_single + extraContent
          );
          toolchainfile_macos_dual = pkgs.writeText "mactoolchain_dual.cmake" (
            toolchain_macos.toolchaintxt_dual + extraContent
          );
          toolchainfile_linux = pkgs.writeText "linuxtoolchain.cmake" (
            toolchain_linux.toolchaintxt + extraContent
          );
          toolchainfile_windows_mingw_x86_64 = pkgs.writeText "windows_mingw_x86_64toolchain.cmake" (
            toolchains_windows_mingw.x86_64.toolchaintxt + extraContent
          );
          toolchainfile_windows_mingw_aarch64 = pkgs.writeText "windows_mingw_aarch64toolchain.cmake" (
            toolchains_windows_mingw.aarch64.toolchaintxt + extraContent
          );
          shellHook = ''
            echo "Create a gc root (to prevent garbage collection of the toolchain) with the following command:"
            echo "nix build .#devShells.${system}.default.inputDerivation -o ./gcroot"
          '';
          #gperftools = pkgs.gperftools;
          #pprof = pkgs.pprof;
        };
    in
    {
      lib = {
        inherit makeDevShell;
      };

      devShells =
        nixpkgs.lib.genAttrs
          [
            "x86_64-linux"
            "aarch64-linux"
            "x86_64-darwin"
            "aarch64-darwin"
          ]
          (system: {
            default = makeDevShell {
              inherit system ; #nixpkgs;
            };
          });
    };

}
