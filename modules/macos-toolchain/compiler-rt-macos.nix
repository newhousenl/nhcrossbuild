{
  stdenv,
  cmake,
  llvmPackagesToUse,
  lib,
  python3,
  macossdk,
  llvmLipo,
  makeWrapper,
  runCommand,
  llvmversion,
  llvmsrc,
  llvmfullversion,
}:
let
  llvmTools = llvmPackagesToUse.bintools-unwrapped;
  deploymentFlags = "-Xarch_x86_64 -mmacos-version-min=10.15 -Xarch_arm64 -mmacos-version-min=11.0";
  platformVersionFlags = "-Xarch_x86_64 -Wl,-platform_version,macos,10.15,${macossdk.version} -Xarch_arm64 -Wl,-platform_version,macos,11.0,${macossdk.version}";
in
stdenv.mkDerivation rec {
  pname = "compiler-rt-macos";
  version = llvmfullversion;

  src = llvmsrc;

  patches = [ ./compiler-rt-macos-1.patch ];

  clang = llvmPackagesToUse.clang-unwrapped;
  nativeBuildInputs = [
    cmake
    python3
    llvmLipo
    llvmPackagesToUse.lld
    llvmTools
  ];
  buildInputs = [ clang ];
  target = "arm64-apple-darwin"; # actually it's going to be a fat library with both x86_64 and arm64

  # -DCMAKE_CXX_FLAGS seem to be ignored in some of the compilation units.
  # So create a wrapper:
  clangwrapped =
    runCommand "wrapped-clang"
      {
        nativeBuildInputs = [ makeWrapper ];
      }
      ''
        mkdir -p $out/bin
        makeWrapper ${clang}/bin/clang $out/bin/clang \
          --add-flags "-isystem ${clang.lib}/lib/clang/${llvmversion}/include ${deploymentFlags} --sysroot=${macossdk} -target ${target}"
        makeWrapper ${clang}/bin/clang++ $out/bin/clang++ \
          --add-flags "-isystem ${clang.lib}/lib/clang/${llvmversion}/include ${deploymentFlags} --sysroot=${macossdk} -target ${target}"
      '';

  cmakeFlags = [
    "-DLLVM_CMAKE_DIR=../llvm/cmake"
    "-G 'Unix Makefiles'" # apparently ninja is not supported by compiler-rt
    "-DCMAKE_BUILD_TYPE=Release"
    "-DCMAKE_SYSTEM_NAME=Darwin"
    "-DCMAKE_INSTALL_PREFIX=$out"
    "-DCMAKE_C_COMPILER_TARGET=${target}"
    "-DCMAKE_CXX_COMPILER_TARGET=${target}"
    "-DCMAKE_C_COMPILER=${clangwrapped}/bin/clang"
    "-DCMAKE_CXX_COMPILER=${clangwrapped}/bin/clang++"
    "-DCMAKE_LIPO=${llvmTools}/bin/llvm-lipo"
    "-DCMAKE_AR=${llvmTools}/bin/llvm-ar"
    "-DCMAKE_RANLIB=${llvmTools}/bin/llvm-ranlib"
    "-DCMAKE_C_FLAGS='${deploymentFlags} -isystem ${clang.lib}/lib/clang/${llvmversion}/include'"
    "-DCMAKE_CXX_FLAGS='${deploymentFlags} -isystem ${clang.lib}/lib/clang/${llvmversion}/include'"
    "-DCMAKE_EXE_LINKER_FLAGS='-fuse-ld=${llvmPackagesToUse.lld}/bin/ld64.lld ${platformVersionFlags}'"
    "-DCMAKE_SHARED_LINKER_FLAGS='-fuse-ld=${llvmPackagesToUse.lld}/bin/ld64.lld ${platformVersionFlags}'"
    "-DCOMPILER_RT_DEFAULT_TARGET_ONLY=ON"
    "-DCOMPILER_RT_BUILD_SANITIZERS=OFF"
    "-DCOMPILER_RT_BUILD_XRAY=OFF"
    "-DCOMPILER_RT_BUILD_LIBFUZZER=OFF"
    "-DCOMPILER_RT_BUILD_MEMPROF=OFF"
    "-DCOMPILER_RT_BUILD_ORC=OFF"
    "-DCOMPILER_RT_ENABLE_IOS=OFF"
    "-DOSX_SYSROOT=${macossdk}"
    "-DCMAKE_OSX_SYSROOT=${macossdk}"
    "-DCMAKE_SYSROOT=${macossdk}"
    "-DCOMPILER_RT_OS_DIR=macos"
    "-DDARWIN_osx_SYSROOT=${macossdk}"
    "-DDARWIN_macosx_OVERRIDE_SDK_VERSION=15.2" # otherwise compiler-rt/cmake/Modules/CompilerRTDarwinUtils.cmake will attempt to run xcrun to determine the SDK version
    "-DCMAKE_VERBOSE_MAKEFILE=ON"
    "-DCMAKE_OSX_ARCHITECTURES=\"arm64;x86_64\""
  ];

  sourceRoot = "source/compiler-rt";

  configurePhase = ''
    runHook preConfigure
    ${cmake}/bin/cmake -G Ninja ${toString cmakeFlags} .
    runHook postConfigure
  '';

  meta = with lib; {
    description = "LLVM compiler-rt runtime for macos cross-compilation";
    license = licenses.ncsa;
    platforms = platforms.all;
  };
}
