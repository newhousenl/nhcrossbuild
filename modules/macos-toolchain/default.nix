{
  stdenv,
  rcodesign,
  callPackage,
  llvmPackagesToUse,
  llvmversion,
  llvmsrc,
  llvmfullversion,
  cdrkit,
  writeText,
}:
let
  macossdk = callPackage ./macossdk.nix { };
  llvmTools = llvmPackagesToUse.bintools-unwrapped;
  llvmLipo = stdenv.mkDerivation {
    pname = "llvm-lipo-in-path";
    version = llvmfullversion;
    dontUnpack = true;
    installPhase = ''
      mkdir -p $out/bin
      ln -s ${llvmTools}/bin/llvm-lipo $out/bin/lipo
    '';
  };
  compiler-rt-macos = callPackage ./compiler-rt-macos.nix {
    inherit
      macossdk
      llvmLipo
      llvmPackagesToUse
      llvmversion
      llvmsrc
      llvmfullversion
      ;
  };
  libdmg-hfsplus = callPackage ./libdmg-hfsplus.nix { };

  # C-only toolchain for building libc++ (bootstrap, similar to Linux approach)
  cmake-macos-toolchaintxt-without-libcpp =
    { dualArchitecture }:
    let
      systemprocessor = if stdenv.hostPlatform.isAarch64 then "arm64" else "x86_64";
      deploymentFlags =
        if dualArchitecture then
          "-Xarch_x86_64 -mmacos-version-min=10.15 -Xarch_arm64 -mmacos-version-min=11.0"
        else if systemprocessor == "arm64" then
          "-mmacos-version-min=11.0"
        else
          "-mmacos-version-min=10.15";
      platformVersionFlags =
        if dualArchitecture then
          "-Xarch_x86_64 -Wl,-platform_version,macos,10.15,${macossdk.version} -Xarch_arm64 -Wl,-platform_version,macos,11.0,${macossdk.version}"
        else if systemprocessor == "arm64" then
          "-Wl,-platform_version,macos,11.0,${macossdk.version}"
        else
          "-Wl,-platform_version,macos,10.15,${macossdk.version}";
      c_flags =
        "${deploymentFlags}"
        + " -target ${systemprocessor}-apple-darwin -resource-dir ${llvmPackagesToUse.clang-unwrapped.lib}/lib/clang/${llvmversion}";
      rtosxlib = "${compiler-rt-macos}/lib/macos/libclang_rt.osx.a";
      cmakeOsxArchs = if dualArchitecture then "x86_64;arm64" else systemprocessor;
      linkerflags = "-fuse-ld=${llvmPackagesToUse.lld}/bin/ld64.lld ${platformVersionFlags} ${rtosxlib}";
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
      set(CMAKE_LINKER "${llvmPackagesToUse.lld}/bin/ld64.lld")
      set(CMAKE_AR "${llvmTools}/bin/llvm-ar")
      set(CMAKE_RANLIB "${llvmTools}/bin/llvm-ranlib")
      set(CMAKE_NM "${llvmTools}/bin/llvm-nm")
      set(CMAKE_OBJDUMP "${llvmTools}/bin/llvm-objdump")
      set(CMAKE_INSTALL_NAME_TOOL "${llvmTools}/bin/llvm-install-name-tool")
      set(CMAKE_STRIP "${llvmTools}/bin/llvm-strip")
      set(CMAKE_LIPO "${llvmTools}/bin/llvm-lipo")

      # llvm-ar preserves universal object files as archive members, which
      # ld64.lld cannot consume. llvm-libtool-darwin creates a proper fat
      # archive with one thin archive per architecture.
      foreach(language C CXX OBJC OBJCXX ASM)
        set(CMAKE_''${language}_ARCHIVE_CREATE "${llvmTools}/bin/llvm-libtool-darwin -static -o <TARGET> <OBJECTS>")
        set(CMAKE_''${language}_ARCHIVE_APPEND "${llvmTools}/bin/llvm-libtool-darwin -static -o <TARGET> <TARGET> <OBJECTS>")
        set(CMAKE_''${language}_ARCHIVE_FINISH "")
      endforeach()

      set(CMAKE_C_FLAGS_INIT "${c_flags}")
      set(CMAKE_OBJC_FLAGS_INIT "${c_flags}")
      set(CMAKE_CXX_FLAGS_INIT "${c_flags}")
      set(CMAKE_OBJCXX_FLAGS_INIT "${c_flags}")
      set(CMAKE_ASM_FLAGS_INIT "${c_flags}")

      set(CMAKE_EXE_LINKER_FLAGS_INIT "${linkerflags}")
      set(CMAKE_SHARED_LINKER_FLAGS_INIT "${linkerflags}")
      set(CMAKE_MODULE_LINKER_FLAGS_INIT "${linkerflags}")

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
    extraNativeBuildInputs = [ llvmLipo ];
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
      set(CMAKE_CXX_FLAGS_INIT "${cppflags} ''${CMAKE_CXX_FLAGS_INIT}")
      set(CMAKE_OBJCXX_FLAGS_INIT "${cppflags} ''${CMAKE_OBJCXX_FLAGS_INIT}")

      # Add static libc++ linking
      set(CMAKE_EXE_LINKER_FLAGS_INIT "''${CMAKE_EXE_LINKER_FLAGS_INIT} ${libcpplinkerflags}")
      set(CMAKE_SHARED_LINKER_FLAGS_INIT "''${CMAKE_SHARED_LINKER_FLAGS_INIT} ${libcpplinkerflags}")
      set(CMAKE_MODULE_LINKER_FLAGS_INIT "''${CMAKE_MODULE_LINKER_FLAGS_INIT} ${libcpplinkerflags}")

      set(NH_RCODESIGN "${rcodesign}/bin/rcodesign")
      set(NH_DMG_COMMAND "${libdmg-hfsplus}/bin/dmg")
      set(NH_GENISOIMAGE_COMMAND "${cdrkit}/bin/genisoimage")
    '';
in
{
  toolchaintxt_single = createToolchainTxt { dualArchitecture = false; };
  toolchaintxt_dual = createToolchainTxt { dualArchitecture = true; };
  nativeBuildInputs = [
    llvmLipo
  ];
}
