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
  cctoolsport ? null,
}:
stdenv.mkDerivation rec {

  # note (18 feb '25): trying to build libcxx;libcxxabi;libunwind;compiler-rt for mingw in one go
  # The toolchain has a sysroot to the mingw crt
  # Doesn't seem to work unfortunately. libunwind depends on either gcc libraries or compiler-rt
  # LLvms cmake is not smart enough to build compiler-rt first and then libunwind
  # Attempting to separately build compiler-rt and then libunwind we're running into a missing __checkstk()
  # function. This is defined in compiler-rt but somehow doesnt get picked up when linking libunwind.
  # Don't know why.
  # Alternative is to build all with gcc, but gcc14 cannot target aarch64-w64-mingw32 yet. It's coming in v15.
  # Then revisit this. mingwcrt/binutils-notused ad mingwcrt/gcccros-notused can probably built then
  # and we'll have a gcc cross toolchain for building libcxx;libcxxabi;libunwind;compiler-rt.
  # UPDATE (Jan 2026): Fixed by building compiler-rt separately first, then passing it to this build.

  pname = "libcpp";
  version = llvmfullversion;

  src = llvmsrc;

  ismingw = lib.strings.hasSuffix "mingw32" hosttriple;
  isdarwin = lib.strings.hasSuffix "darwin" hosttriple;

  patches =
    [ ]
    ++ (lib.optional ismingw [
      ./1.patch
      ./2.patch
    ]);

  nativeBuildInputs = [
    cmake
    python3
    llvmPackagesToUse.lld
    llvmPackagesToUse.bintools-unwrapped
  ]
  ++ lib.optionals (cctoolsport != null) [ cctoolsport ];
  buildInputs = [ ninja ];

  cmakeFlags = [
    "-DCMAKE_BUILD_TYPE=Release"
    #"-DCOMPILER_RT_BUILD_BUILTINS=ON"
    #"-DLLVM_ENABLE_LIBCXX=ON"
    #"-DCOMPILER_RT_DEFAULT_TARGET_TRIPLE=${hosttriple}"
    #"-DLLVM_ENABLE_RUNTIMES=\"libcxx;libcxxabi;libunwind;compiler-rt\""
    "-DCMAKE_TOOLCHAIN_FILE=${toolchainfile}"
    "-DCMAKE_INSTALL_PREFIX=$out"
    "-DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY"
  ]
  ++ (
    if ismingw then
      [
        # Only build libcxx, libcxxabi, and libunwind (compiler-rt is already built separately)
        "-DLLVM_ENABLE_RUNTIMES=\"libcxx;libcxxabi;libunwind\""
        "-DLIBUNWIND_USE_COMPILER_RT=ON"
        "-DLIBCXXABI_USE_COMPILER_RT=ON"
        "-DLIBCXX_USE_COMPILER_RT=ON"
        "-DLIBCXXABI_USE_LLVM_UNWINDER=ON"
        "-DLIBCXX_USE_LLVM_UNWINDER=ON"
        "-DLIBCXX_ENABLE_SHARED=OFF"
        "-DLIBCXX_ENABLE_STATIC=ON"
        "-DLIBCXXABI_ENABLE_SHARED=OFF"
        "-DLIBCXXABI_ENABLE_STATIC=ON"
        "-DLIBUNWIND_ENABLE_SHARED=OFF"
        "-DLIBUNWIND_ENABLE_STATIC=ON"
      ]
    else if isdarwin then
      [
        "-DLLVM_ENABLE_RUNTIMES=\"libcxx;libcxxabi;libunwind\""
        "-DLIBCXX_HERMETIC_STATIC_LIBRARY=ON"
        "-DLIBCXX_ENABLE_SHARED=OFF"
        "-DLIBCXX_ENABLE_STATIC=ON"
        "-DLIBCXXABI_ENABLE_SHARED=OFF"
        "-DLIBCXXABI_ENABLE_STATIC=ON"
        "-DLIBCXXABI_USE_LLVM_UNWINDER=ON"
        "-DLIBCXX_USE_LLVM_UNWINDER=ON"
        "-DLIBUNWIND_ENABLE_SHARED=OFF"
        "-DLIBUNWIND_ENABLE_STATIC=ON"
      ]
    else
      [
        "-DLLVM_ENABLE_RUNTIMES=\"libcxx;libcxxabi;libunwind\""
        #"-DLLVM_ENABLE_RUNTIMES=\"libcxx;libcxxabi;libunwind\""
      ]
  );

  configurePhase = ''
    runHook preConfigure
    set -x
    cat ${toolchainfile}
    ${cmake}/bin/cmake -G Ninja ${toString cmakeFlags} -S ./runtimes -B ./build
    set +x
    runHook postConfigure
  '';

  buildPhase = ''
    runHook preBuild
    set -x
    ${cmake}/bin/cmake --build ./build
    set +x
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    set -x
    ${cmake}/bin/cmake --install ./build
    
    echo "Files in output:"
    find $out -ls
    
    # Fix archive indices
    ${if ismingw then ''
      echo "Running ranlib on archives..."
      find $out -name "*.a" -print0 | xargs -0 -I {} ${llvmPackagesToUse.bintools-unwrapped}/bin/llvm-ranlib {}
    '' else ""}
    
    set +x
    runHook postInstall
  '';

  meta = with lib; {
    description = "Libc++";
    license = licenses.ncsa;
    platforms = lib.platforms.all;
  };
}
