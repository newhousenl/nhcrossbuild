{
  stdenv,
  lib,
  callPackage,
  llvmPackagesToUse,
  writeText,
  llvmversion,
  llvmsrc,
  llvmfullversion,
  debianversion ? 10,
  arch ? "amd64",
}:
let
  debsysroot = callPackage ./debsysroot/default.nix {
    inherit debianversion arch;
  };
  c_and_cppflags = "-target x86_64-pc-linux-gnu -resource-dir ${llvmPackagesToUse.clang-unwrapped.lib}/lib/clang/${llvmversion}";
  linkerflags = "-fuse-ld=lld --ld-path=${llvmPackagesToUse.lld}/bin/ld.lld -Wl,-dynamic-linker -Wl,/lib64/ld-linux-x86-64.so.2 -L ${llvmPackagesToUse.clang-unwrapped.lib}/lib -L ${debsysroot}/usr/lib/x86_64-linux-gnu";
  cmake-linux-toolchaintxt-without-libcpp = ''
    set(CMAKE_SYSTEM_NAME Linux)
    set(CMAKE_SYSTEM_PROCESSOR x86_64)
    set(CMAKE_SYSROOT ${debsysroot})

    set(CMAKE_C_COMPILER "${llvmPackagesToUse.clang-unwrapped}/bin/clang")
    set(CMAKE_CXX_COMPILER "${llvmPackagesToUse.clang-unwrapped}/bin/clang++")
    set(CMAKE_AR "${llvmPackagesToUse.bintools-unwrapped}/bin/llvm-ar")
    set(CMAKE_RANLIB "${llvmPackagesToUse.bintools-unwrapped}/bin/llvm-ranlib")
    set(CMAKE_STRIP "${llvmPackagesToUse.bintools-unwrapped}/bin/llvm-strip")

    set(CMAKE_C_FLAGS "${c_and_cppflags} ''${CMAKE_C_FLAGS}")
    set(CMAKE_CXX_FLAGS "${c_and_cppflags} -nostdlib++ ''${CMAKE_CXX_FLAGS}")
    set(CMAKE_ASM_FLAGS "${c_and_cppflags} ''${CMAKE_ASM_FLAGS}")
    set(CMAKE_EXE_LINKER_FLAGS "''${CMAKE_EXE_LINKER_FLAGS} ${linkerflags}")
    set(CMAKE_SHARED_LINKER_FLAGS "''${CMAKE_SHARED_LINKER_FLAGS} ${linkerflags}")

    # Configure pkg-config to use the sysroot
    unset(ENV{PKG_CONFIG_PATH})  # set by nix
    unset(ENV{NIX_PKG_CONFIG_WRAPPER_TARGET_HOST_x86_64_unknown_linux_gnu})  # set by nix
    set(ENV{PKG_CONFIG_SYSROOT_DIR} ${debsysroot})
    set(ENV{PKG_CONFIG_LIBDIR} "${debsysroot}/usr/local/share/pkgconfig:${debsysroot}/usr/lib/x86_64-linux-gnu/pkgconfig:${debsysroot}/usr/share/pkgconfig")

    set(CMAKE_FIND_ROOT_PATH ${debsysroot})
    set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)  # find programs on the host
    set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)   # libraries, includes only under CMAKE_SYSROOT
    set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
    set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

    # because Nix modfies this. It is needed to search for system libraries.
    # CMake will prefix this with CMAKE_FIND_ROOT_PATH:
    set(CMAKE_SYSTEM_PREFIX_PATH "/usr;/usr/local")
  '';
  libcpplinux = callPackage ../libcpp/default.nix {
    toolchainfile = writeText "toolchain.cmake" cmake-linux-toolchaintxt-without-libcpp;
    hosttriple = "x86_64-pc-linux-gnu";
    inherit llvmPackagesToUse llvmsrc llvmfullversion;
  };
in
{
  toolchaintxt = ''
    ${cmake-linux-toolchaintxt-without-libcpp}
    set(CMAKE_EXE_LINKER_FLAGS "''${CMAKE_EXE_LINKER_FLAGS}  -L ${libcpplinux}/lib -Wl,-Bstatic -lc++ -lc++abi -Wl,-Bdynamic")
    set(CMAKE_CXX_FLAGS "-nostdinc++ -isystem ${libcpplinux}/include/c++/v1 ''${CMAKE_CXX_FLAGS}")
  '';
  nativeBuildInputs = [ ];
}
