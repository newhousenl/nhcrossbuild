# Windows MinGW Toolchain for Nix
#
# This module builds a complete MinGW-w64 cross-compilation toolchain using LLVM/Clang.
# It supports both x86_64-w64-mingw32 and aarch64-w64-mingw32 targets.

{ stdenv, lib, callPackage, target, llvmPackagesToUse, llvmversion, llvmsrc, llvmfullversion, fetchurl, nsis, makeWrapper, gawk, gnused }:

let
  pertargetparams = {
    x86_64 = {
      targettriple = "x86_64-w64-mingw32";
      targetc_cppflags = "";
      systemprocessor = "AMD64";
      mingwcrtflags = "--disable-libarm32 --disable-libarm64 --disable-lib32 --enable-lib64";
      builtinsSuffix = "x86_64";
      libdir = "x64";
    };
    aarch64 = {
      targettriple = "aarch64-w64-mingw32";
      # -march=armv8.2-a: Target ARMv8.2-A architecture
      targetc_cppflags = "-march=armv8.2-a";
      systemprocessor = "ARM64";
      mingwcrtflags = "--disable-libarm32 --enable-libarm64 --disable-lib32 --disable-lib64";
      builtinsSuffix = "aarch64";
      libdir = "arm64";
    };
  };

  targetparams = pertargetparams.${target};
  
  # LLVM uses a normalized triple format (windows-gnu instead of mingw32)
  normalizedtriple = lib.replaceStrings ["mingw32"] ["windows-gnu"] targetparams.targettriple;

  # Create wrappers for clang/clang++ with the target triple baked in.
  # This ensures that all compilation (including preprocessing by llvm-rc) 
  # uses the correct target architecture.
  wrapped-clang-basic = stdenv.mkDerivation {
    pname = "wrapped-clang-${target}";
    version = "1.0";
    dontUnpack = true;
    nativeBuildInputs = [ makeWrapper ];
    installPhase = ''
      mkdir -p $out/bin
      # Wrap clang with target flag
      makeWrapper ${llvmPackagesToUse.clang-unwrapped}/bin/clang $out/bin/clang \
        --add-flags "-target ${targetparams.targettriple}" \
        --add-flags "-resource-dir ${llvmPackagesToUse.clang-unwrapped.lib}/lib/clang/${llvmversion}"
      
      # Wrap clang++ with target flag
      makeWrapper ${llvmPackagesToUse.clang-unwrapped}/bin/clang++ $out/bin/clang++ \
        --add-flags "-target ${targetparams.targettriple}" \
        --add-flags "-resource-dir ${llvmPackagesToUse.clang-unwrapped.lib}/lib/clang/${llvmversion}"
      
      # Symlink other tools
      ln -s ${llvmPackagesToUse.bintools-unwrapped}/bin/llvm-ar $out/bin/llvm-ar
      ln -s ${llvmPackagesToUse.bintools-unwrapped}/bin/llvm-ranlib $out/bin/llvm-ranlib
      ln -s ${llvmPackagesToUse.bintools-unwrapped}/bin/llvm-dlltool $out/bin/llvm-dlltool
      ln -s ${llvmPackagesToUse.bintools-unwrapped}/bin/llvm-rc $out/bin/llvm-rc
      ln -s ${llvmPackagesToUse.bintools-unwrapped}/bin/llvm-nm $out/bin/llvm-nm
      ln -s ${llvmPackagesToUse.bintools-unwrapped}/bin/llvm-nm $out/bin/nm
      
      ${lib.optionalString stdenv.isDarwin ''
      ln -s ${llvmPackagesToUse.lld}/bin/ld.lld $out/bin/ld.lld

      # Create ld wrapper for MinGW cross-compilation.
      # Wraps ld.lld and ensures configure's libtool detection works:
      # - "ld --help" must contain "auto-import" for shared library support
      # - "ld -v" output from lld already contains "GNU" (compatible with GNU linkers)
      # Without this, configure may set ld_shlibs=no on macOS because ld.lld's
      # default (ELF) --help output may not list MinGW-specific flags.
      {
        echo '#!/bin/sh'
        echo 'if printf "%s " "$@" | grep -q -- "--help"; then'
        echo '  ${llvmPackagesToUse.lld}/bin/ld.lld "$@" 2>&1 || true'
        echo '  echo "  --enable-auto-import"'
        echo 'else'
        echo '  exec ${llvmPackagesToUse.lld}/bin/ld.lld "$@"'
        echo 'fi'
      } > $out/bin/ld
      chmod +x $out/bin/ld
      ''}

      # Symlink or create llvm-windres
      if [ -f "${llvmPackagesToUse.bintools-unwrapped}/bin/llvm-windres" ]; then
        ln -s ${llvmPackagesToUse.bintools-unwrapped}/bin/llvm-windres $out/bin/llvm-windres
      else
        ln -s ${llvmPackagesToUse.bintools-unwrapped}/bin/llvm-rc $out/bin/llvm-windres
      fi
    '';
  };

  # ============================================================================
  # MinGW-w64 C Runtime
  # ============================================================================
  # Builds headers, CRT, and winpthreads for the target architecture.
  # Uses UCRT (Universal C Runtime) as the default C runtime.
  mingwcrt = stdenv.mkDerivation {
    pname = "mingwcrt";
    version = "13.0.0a";

    src = fetchurl {
      url = "https://github.com/mingw-w64/mingw-w64/archive/9dad98f51b71710794786b6e9924a5ac996e447b.tar.gz";
      name = "mingw-w64-9dad98f51b71710794786b6e9924a5ac996e447b.tar.gz";
      hash = "sha256-/VZWYdWhvEt+wbZtRVtiUYdvoC6s3JpwIZxsW+kNJHA=";
    };

    nativeBuildInputs = [ wrapped-clang-basic makeWrapper gawk gnused];

    dontConfigure = true; # We manually configure subcomponents in buildPhase
    dontInstall = true;   # We install subcomponents in buildPhase

    buildPhase = ''
      runHook preBuild
      
      # 1. Build and install headers
      echo "Configuring and building MinGW-w64 headers..."
      mkdir -p build-headers
      cd build-headers
      ../mingw-w64-headers/configure \
        --prefix=$out/${targetparams.targettriple} \
        --host=${targetparams.targettriple} \
        --with-default-msvcrt=ucrt
      make -j$(nproc)
      make install
      cd ..
      
      # Prepare environment for CRT and Winpthreads
      # We export common variables to avoid repetition
      export CPPFLAGS="-I$out/${targetparams.targettriple}/include"
      export CFLAGS="-I$out/${targetparams.targettriple}/include"
      export CXXFLAGS="-I$out/${targetparams.targettriple}/include"
      export LDFLAGS="-L$out/${targetparams.targettriple}/lib"
      
      # Ensure wrapped tools are used and found
      export PATH="${wrapped-clang-basic}/bin:$PATH"
      
      ${lib.optionalString stdenv.isDarwin ''
      # Darwin-only: pre-cache lt_cv_sys_global_symbol_pipe so configure's libtool
      # nm-pipe test is skipped.  The test compiles + links a full Windows PE binary
      # to verify the pipe, but that link step fails on macOS (no CRT/startup libs
      # exist yet at this point — chicken-and-egg).  Exporting the correct value
      # makes autoconf use it directly without running the broken verification.
      # This workaround is not needed on Linux where the link step succeeds.
      export lt_cv_sys_global_symbol_pipe="${gnused}/bin/sed -n -e 's/^.*[	 ]\([ABCDGISTW][ABCDGISTW]*\)[	 ]*\([_A-Za-z][_A-Za-z0-9]*\)$/\1 \2 \2/p'"
      # Also pre-cache GNU ld detection: lld is GNU ld-compatible but macOS's
      # system ld is not.  Without this, configure detects with_gnu_ld=no and
      # libtool falls into an MSVC code path where 'cl*' glob matches 'clang',
      # generating -link -EXPORT: flags that clang's GNU driver doesn't understand.
      export lt_cv_prog_gnu_ld=yes
      ''}

      # Common configure arguments for both CRT and Winpthreads
      # Explicitly passing tools ensures cross-compilation uses correct binaries
      # Note: RC needs special flags for includes and target
      COMMON_CONF_ARGS=" \
        --host=${targetparams.targettriple} \
        --prefix=$out/${targetparams.targettriple} \
        CC=${wrapped-clang-basic}/bin/clang \
        CXX=${wrapped-clang-basic}/bin/clang++ \
        AR=${wrapped-clang-basic}/bin/llvm-ar \
        RANLIB=${wrapped-clang-basic}/bin/llvm-ranlib \
        DLLTOOL=${wrapped-clang-basic}/bin/llvm-dlltool \
        NM=${wrapped-clang-basic}/bin/llvm-nm \
        ${lib.optionalString stdenv.isDarwin "LD=${wrapped-clang-basic}/bin/ld"} \
      "

      # 2. Build CRT (C Runtime)
      echo "Configuring and building MinGW-w64 CRT..."
      mkdir -p build-crt
      cd build-crt
      
      ../mingw-w64-crt/configure \
        $COMMON_CONF_ARGS \
        --disable-multilib \
        ${targetparams.mingwcrtflags} \
        --with-default-msvcrt=ucrt \
        RC="${wrapped-clang-basic}/bin/llvm-windres --target=${targetparams.targettriple}"
      
      make -j$(nproc)
      make install
      cd ..

      ${lib.optionalString (stdenv.isDarwin && target == "aarch64") ''
      # AArch64 bootstrap: provide __chkstk in libmingw32.a
      #
      # On x86/x64, the mingw-w64 CRT's dll_dependency.S provides __chkstk and
      # __alloca (guarded by #if defined(__i386__) || defined(__x86_64__)).
      # On AArch64, __chkstk is normally provided by compiler-rt builtins, but
      # compiler-rt depends on the CRT we are building right now.
      #
      # To break this circular dependency, compile the AArch64 __chkstk from
      # the LLVM compiler-rt reference implementation and add it directly to
      # libmingw32.a.  This mirrors what dll_dependency.S does for x86/x64.
      echo "Adding AArch64 __chkstk to libmingw32.a..."
      cat > /tmp/chkstk_aarch64.S << '___CHKSTK_EOF___'
      // AArch64 __chkstk - from LLVM compiler-rt (Apache-2.0 WITH LLVM-exception)
      // Input: x15 = allocation size in 16-byte units
      // Probes each stack page from SP downward.  Clobbers x16, x17.
      // Does NOT modify SP (caller does: sub sp, sp, x15, lsl #4).
      .globl __chkstk
      .p2align 2
      __chkstk:
          lsl    x16, x15, #4
          mov    x17, sp
      1:
          sub    x17, x17, #4096
          subs   x16, x16, #4096
          ldr    xzr, [x17]
          b.gt   1b
          ret
      ___CHKSTK_EOF___
      ${wrapped-clang-basic}/bin/clang -c /tmp/chkstk_aarch64.S -o /tmp/chkstk_aarch64.o
      ${wrapped-clang-basic}/bin/llvm-ar rcs $out/${targetparams.targettriple}/lib/libmingw32.a /tmp/chkstk_aarch64.o
      ''}

      # 3. Build winpthreads
      echo "Configuring and building MinGW-w64 Winpthreads..."
      mkdir -p build-winpthreads
      cd build-winpthreads
      
      ../mingw-w64-libraries/winpthreads/configure \
        $COMMON_CONF_ARGS \
        --enable-static --enable-shared \
        RC="${wrapped-clang-basic}/bin/llvm-windres --target=${targetparams.targettriple} -I$out/${targetparams.targettriple}/include"
      
      make -j$(nproc)
      make install
      
      runHook postBuild
    '';

    meta = with lib; {
      description = "MinGW-w64 C Runtime with UCRT";
      license = licenses.zlib;
      platforms = platforms.unix;
    };
  };

  makeToolchainConfig = { 
    extraCxxFlags ? "",
    extraLinkerFlags ? "",
    standardLibraryPaths ? "",
    resourceDir ? "${llvmPackagesToUse.clang-unwrapped.lib}/lib/clang/${llvmversion}"
  }: ''
    set(CMAKE_SYSTEM_NAME Windows)
    set(CMAKE_SYSTEM_PROCESSOR ${targetparams.systemprocessor})
    set(CMAKE_C_COMPILER_TARGET ${targetparams.targettriple})
    set(CMAKE_CXX_COMPILER_TARGET ${targetparams.targettriple})
    set(CMAKE_ASM_COMPILER_TARGET ${targetparams.targettriple})
    set(CMAKE_SYSROOT ${mingwcrt}/${targetparams.targettriple})

    set(CMAKE_C_COMPILER "${llvmPackagesToUse.clang-unwrapped}/bin/clang")
    set(CMAKE_CXX_COMPILER "${llvmPackagesToUse.clang-unwrapped}/bin/clang++")
    set(CMAKE_AR "${llvmPackagesToUse.bintools-unwrapped}/bin/llvm-ar")
    set(CMAKE_RANLIB "${llvmPackagesToUse.bintools-unwrapped}/bin/llvm-ranlib")
    set(CMAKE_STRIP "${llvmPackagesToUse.bintools-unwrapped}/bin/llvm-strip")
    set(CMAKE_NM "${llvmPackagesToUse.bintools-unwrapped}/bin/llvm-nm")
    set(CMAKE_RC_COMPILER "${wrapped-clang-basic}/bin/llvm-rc")

    set(NH_C_CXX_FLAGS "-target ${targetparams.targettriple} -resource-dir ${resourceDir} -fno-omit-frame-pointer -fms-extensions ${targetparams.targetc_cppflags} -gcodeview")
    set(CMAKE_C_FLAGS "''${NH_C_CXX_FLAGS} ''${CMAKE_C_FLAGS}")
    set(CMAKE_RC_FLAGS "''${NH_C_CXX_FLAGS} ''${CMAKE_RC_FLAGS}")
    set(CMAKE_CXX_FLAGS "''${NH_C_CXX_FLAGS}${extraCxxFlags} ''${CMAKE_CXX_FLAGS}")

    set(NH_LINKER_FLAGS "-fuse-ld=lld --ld-path=${llvmPackagesToUse.lld}/bin/ld.lld --unwindlib=none -Wno-unused-command-line-argument${extraLinkerFlags}${standardLibraryPaths}")
    set(CMAKE_EXE_LINKER_FLAGS "''${CMAKE_EXE_LINKER_FLAGS} ''${NH_LINKER_FLAGS}")
    set(CMAKE_SHARED_LINKER_FLAGS "''${CMAKE_SHARED_LINKER_FLAGS} ''${NH_LINKER_FLAGS}")
    
    # Disable pkg-config completely, we don't need it for Windows
    set(ENV{PKG_CONFIG_LIBDIR} "")

    set(CMAKE_FIND_ROOT_PATH ''${CMAKE_SYSROOT})
    set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
    set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
    set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
    set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
  '';

  
  # Basic toolchain for building compiler-rt (without compiler-rt itself)
  toolchainfile_basic = stdenv.mkDerivation {
    name = "toolchain-basic";
    dontUnpack = true;
    installPhase = ''
      cat > $out <<'EOF'
      ${makeToolchainConfig {}}
      EOF
    '';
  };

  # Build compiler-rt builtins
  compilerrt = callPackage ../compiler-rt/default.nix {
    inherit llvmPackagesToUse llvmsrc llvmfullversion;
    toolchainfile = "${toolchainfile_basic}";
    hosttriple = targetparams.targettriple;
  };

  # Create a clang resource directory with compiler-rt in the expected location
  clang_with_compilerrt = stdenv.mkDerivation {
    name = "clang-with-compilerrt";
    dontUnpack = true;
    installPhase = ''
      mkdir -p $out/lib/clang/${llvmversion}/lib/${normalizedtriple}
      mkdir -p $out/lib/clang/${llvmversion}/include
      
      # Copy compiler-rt builtins
      cp ${compilerrt}/lib/windows/* $out/lib/clang/${llvmversion}/lib/${normalizedtriple}/
      
      # Create convenience symlink without arch suffix
      if [ -f "$out/lib/clang/${llvmversion}/lib/${normalizedtriple}/libclang_rt.builtins-${targetparams.builtinsSuffix}.a" ]; then
        ln -s libclang_rt.builtins-${targetparams.builtinsSuffix}.a \
          $out/lib/clang/${llvmversion}/lib/${normalizedtriple}/libclang_rt.builtins.a
      fi
      
      # Copy clang's builtin includes
      cp -r ${llvmPackagesToUse.clang-unwrapped.lib}/lib/clang/${llvmversion}/include/* $out/lib/clang/${llvmversion}/include/
    '';
  };

  toolchainfile_with_compilerrt = stdenv.mkDerivation {
    name = "toolchain-with-compilerrt";
    dontUnpack = true;
    installPhase = ''
      cat > $out <<'EOF'
      ${makeToolchainConfig {
        extraCxxFlags = " -fsized-deallocation";
        extraLinkerFlags = " -rtlib=compiler-rt -nostdlib++ -lclang_rt.builtins-${targetparams.builtinsSuffix}";
        standardLibraryPaths = " -L${clang_with_compilerrt}/lib/clang/${llvmversion}/lib/${normalizedtriple}";
        resourceDir = "${clang_with_compilerrt}/lib/clang/${llvmversion}";
      }}
      EOF
    '';
  };

  # Build libc++ with MinGW
  libcppmingw = callPackage ../libcpp/default.nix {
    inherit llvmPackagesToUse llvmsrc llvmfullversion;
    toolchainfile = "${toolchainfile_with_compilerrt}";
    hosttriple = targetparams.targettriple;
  };

  additionaltoolchainconfig = ''
      set(MAKENSIS_EXE ${nsis}/bin/makensis)
  '';
in {  
  toolchaintxt = makeToolchainConfig {
    extraCxxFlags = " -fsized-deallocation -nostdinc++ -isystem ${libcppmingw}/include/c++/v1";
    extraLinkerFlags = " -rtlib=compiler-rt -nostdlib++  -Wl,--whole-archive -lclang_rt.builtins-${targetparams.builtinsSuffix} -Wl,--no-whole-archive -lc++ -lc++abi -lunwind -lwinpthread -lmingwex";
    standardLibraryPaths = " -L${clang_with_compilerrt}/lib/clang/${llvmversion}/lib/${normalizedtriple} -L${libcppmingw}/lib";
    resourceDir = "${clang_with_compilerrt}/lib/clang/${llvmversion}";
  } + additionaltoolchainconfig;

  nativeBuildInputs = [ ];
}
