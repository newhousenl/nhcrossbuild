{
  stdenv,
  rcodesign,
  callPackage,
  llvmPackagesToUse,
  llvmversion,
  llvmsrc,
  llvmfullversion,
  lib,
  cdrkit,
  writeText,
  cctools,
  ld64,
}:
let
  macossdk = callPackage ./macossdk.nix { };
  compiler-rt-macos = callPackage ./compiler-rt-macos.nix {
    inherit
      macossdk
      llvmPackagesToUse
      llvmversion
      llvmsrc
      llvmfullversion
      ;
  };
  libdmg-hfsplus = callPackage ./libdmg-hfsplus.nix { };
  cctools-port = callPackage ./cctools-port/cctools-port.nix { };
  #cctools-touse = cctools-port;
  cctools-touse = if stdenv.isDarwin then cctools else cctools-port;
  lipo-in-path = stdenv.mkDerivation {
    # just create a symlink to the lipo binary in the cctools-port
    pname = "lipo-in-path";
    version = "1.0";
    dontUnpack = true;
    installPhase = ''
      mkdir -p $out/bin
      ln -s ${cctools-touse}/bin/lipo $out/bin/lipo
    '';
  };
  ldpackage = if stdenv.isDarwin then ld64 else cctools-port;

  # C-only toolchain for building libc++ (bootstrap, similar to Linux approach)
  cmake-macos-toolchaintxt-without-libcpp =
    { dualArchitecture }:
    let
      systemprocessor = stdenv.hostPlatform.linuxArch;
      c_flags =
        (if stdenv.isDarwin then "" else "-mlinker-version=951")
        + " -mmacos-version-min=10.15"
        + " -target ${systemprocessor}-apple-darwin -resource-dir ${llvmPackagesToUse.clang-unwrapped.lib}/lib/clang/${llvmversion}";
        #+ " -fuse-lipo=cctools-lipo";
      rtosxlib = "${compiler-rt-macos}/lib/macos/libclang_rt.osx.a";
      cmakeOsxArchs = if dualArchitecture then "x86_64;arm64" else systemprocessor;
      linkerflags = "-fuse-ld=ld64 --ld-path=${ldpackage}/bin/ld ${rtosxlib}";
    in
    ''
      set(CMAKE_SYSTEM_NAME Darwin)
      set(CMAKE_SYSTEM_PROCESSOR "${systemprocessor}")
      set(CMAKE_OSX_ARCHITECTURES "${cmakeOsxArchs}" CACHE STRING "Target architectures")

      # This is required for FindPackage(Threads)
      set(CMAKE_THREAD_LIBS_INIT "-lpthread")
      set(CMAKE_HAVE_THREADS_LIBRARY 1)
      set(CMAKE_USE_WIN32_THREADS_INIT 0)
      set(CMAKE_USE_PTHREADS_INIT 1)
      set(THREADS_PREFER_PTHREAD_FLAG ON)

      set(CMAKE_C_COMPILER "${llvmPackagesToUse.clang-unwrapped}/bin/clang")
      set(CMAKE_CXX_COMPILER "${llvmPackagesToUse.clang-unwrapped}/bin/clang++")
      set(CMAKE_AR "${cctools-touse}/bin/ar")
      set(CMAKE_RANLIB "${cctools-touse}/bin/ranlib")
      set(CMAKE_INSTALL_NAME_TOOL "${cctools-touse}/bin/install_name_tool")
      set(CMAKE_STRIP "${cctools-touse}/bin/strip")
      set(CMAKE_LIPO "${cctools-touse}/bin/lipo")

      set(CMAKE_C_FLAGS "${c_flags} ''${CMAKE_C_FLAGS}")
      set(CMAKE_OBJC_FLAGS "${c_flags} ''${CMAKE_OBJC_FLAGS}")
      set(CMAKE_CXX_FLAGS "${c_flags} ''${CMAKE_CXX_FLAGS}")
      set(CMAKE_OBJCXX_FLAGS "${c_flags} ''${CMAKE_OBJCXX_FLAGS}")
      set(CMAKE_ASM_FLAGS "${c_flags} ''${CMAKE_ASM_FLAGS}")

      set(CMAKE_EXE_LINKER_FLAGS "''${CMAKE_EXE_LINKER_FLAGS} ${linkerflags}")
      set(CMAKE_SHARED_LINKER_FLAGS "''${CMAKE_SHARED_LINKER_FLAGS} ${linkerflags}")

      set(CMAKE_OSX_SYSROOT ${macossdk}/)
      set(CMAKE_FIND_ROOT_PATH ${macossdk})

      set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)  # find programs on the host
      set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)   # libraries, includes only in the target
      set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
      set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
    '';

  libcppmacos = callPackage ../libcpp/default.nix {
    toolchainfile = writeText "toolchain.cmake" (cmake-macos-toolchaintxt-without-libcpp {
      dualArchitecture = true;
    });
    hosttriple = "universal-apple-darwin";
    cctoolsport = cctools-touse;
    inherit llvmPackagesToUse llvmsrc llvmfullversion;
  };

  createToolchainTxt =
    { dualArchitecture }:
    let
      cppflags = "-nostdinc++ -isystem ${libcppmacos}/include/c++/v1";
      libcpplinkerflags = "-nostdlib++ -Wl,-force_load,${libcppmacos}/lib/libc++.a -Wl,-force_load,${libcppmacos}/lib/libc++abi.a -Wl,-force_load,${libcppmacos}/lib/libunwind.a";
    in
    ''
      ${cmake-macos-toolchaintxt-without-libcpp { inherit dualArchitecture; }}

      # Add C++ standard library flags
      set(CMAKE_CXX_FLAGS "${cppflags} ''${CMAKE_CXX_FLAGS}")
      set(CMAKE_OBJCXX_FLAGS "${cppflags} ''${CMAKE_OBJCXX_FLAGS}")

      # Add static libc++ linking
      set(CMAKE_EXE_LINKER_FLAGS "''${CMAKE_EXE_LINKER_FLAGS} ${libcpplinkerflags}")
      set(CMAKE_SHARED_LINKER_FLAGS "''${CMAKE_SHARED_LINKER_FLAGS} ${libcpplinkerflags}")

      set(NH_RCODESIGN "${rcodesign}/bin/rcodesign")
      set(NH_DMG_COMMAND "${libdmg-hfsplus}/bin/dmg")
      set(NH_GENISOIMAGE_COMMAND "${cdrkit}/bin/genisoimage")
    '';
in
{
  toolchaintxt_single = createToolchainTxt { dualArchitecture = false; };
  toolchaintxt_dual = createToolchainTxt { dualArchitecture = true; };
  nativeBuildInputs = [
    lipo-in-path
  ]
  ++ lib.optional stdenv.isDarwin [ ld64 ]; # keep ld in PATH, otherwise some strange bug will cause /usr/bin/ld to be called and do an infinite recursion.
}
