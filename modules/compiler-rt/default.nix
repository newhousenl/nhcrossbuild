{
  stdenv,
  cmake,
  ninja,
  lib,
  python3,
  llvmPackagesToUse,
  toolchainfile,
  hosttriple,
  llvmsrc,
  llvmfullversion,
}:
stdenv.mkDerivation rec {
  pname = "compiler-rt";
  version = llvmfullversion;

  src = llvmsrc;

  nativeBuildInputs = [
    cmake
    python3
    llvmPackagesToUse.lld
    llvmPackagesToUse.bintools-unwrapped
  ];
  buildInputs = [ ninja ];

  patches = [ ./disable-version-script.patch ];

  ismingw = lib.strings.hasSuffix "mingw32" hosttriple;

  configurePhase = ''
    runHook preConfigure
    mkdir -p build
    cd build
    cmake -G Ninja \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_TOOLCHAIN_FILE=${toolchainfile} \
      -DCMAKE_INSTALL_PREFIX=''${out} \
      -DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY \
      -DCOMPILER_RT_BUILD_BUILTINS=ON \
      -DCOMPILER_RT_DEFAULT_TARGET_TRIPLE=${hosttriple} \
      -DCOMPILER_RT_BUILD_SANITIZERS=OFF \
      -DCOMPILER_RT_BUILD_XRAY=OFF \
      -DCOMPILER_RT_BUILD_LIBFUZZER=OFF \
      -DCOMPILER_RT_BUILD_MEMPROF=OFF \
      -DCOMPILER_RT_BUILD_ORC=OFF \
      -DCOMPILER_RT_BUILD_PROFILE=OFF \
      ../compiler-rt
    runHook postConfigure
  '';

  buildPhase = ''
    runHook preBuild
    cmake --build . -j$NIX_BUILD_CORES
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    cmake --install .
    
    echo "Files in output:"
    find $out -ls
    
    # Fix archive indices
    ${if ismingw then ''
      echo "Running ranlib on archives..."
      find $out -name "*.a" -print0 | xargs -0 -I {} ${llvmPackagesToUse.bintools-unwrapped}/bin/llvm-ranlib {}
    '' else ""}
    
    runHook postInstall
  '';

  meta = with lib; {
    description = "Compiler runtime libraries for Windows MinGW";
    license = licenses.ncsa;
    platforms = platforms.unix;
  };
}
