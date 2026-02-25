{ clangStdenv, stdenv, fetchFromGitHub, lib, xar, autoconf, automake, libtool, patch, libblocksruntime, callPackage, libxml2 }:
let
  xar_patched = 
    xar.overrideAttrs (oldAttrs: {
    # https://github.com/NixOS/nixpkgs/pull/368920/files
    env.NIX_CFLAGS_COMPILE = toString (
      [
        # For some reason libxml2 package headers are in subdirectory and thus aren’t
        # picked up by stdenv’s C compiler wrapper (see ccWrapper_addCVars). This
        # doesn’t really belong here and either should be part of libxml2 package or
        # libxml2 in Nixpkgs can just fix their header paths.
        "-isystem ${libxml2.dev}/include/libxml2"
      ]
      ++ lib.optionals stdenv.cc.isGNU [
        # fix build on GCC 14
        "-Wno-error=implicit-function-declaration"
        "-Wno-error=incompatible-pointer-types"
      ]
    );          
  });
  apple-libdispatch-port = callPackage ./apple-libdispatch-port.nix { };
in clangStdenv.mkDerivation rec {
  pname = "cctools-port";
#  version = "877.8-ld64-253.9-1";
  version = "1010.6-ld64-951.9";

  src = fetchFromGitHub {
    owner = "tpoechtrager";
    repo = "cctools-port";
    #rev = "cctools-${version}";
    rev = "81f205e8ca6bbf2fdbcb6948132454fd1f97839e";
    hash = "sha256-a5ip0e/nQrCOEwIO3qrNGP8246cjEXNPk2/TQnccZU4=";
  };

  libtapi-port = callPackage ./tpoechtrager-libtapi.nix { };

  #srcsubdir = "./cctools";

  nativeBuildInputs = [ 
    libtapi-port xar_patched autoconf automake libtool libblocksruntime apple-libdispatch-port
  ];

  #patches = [ ./001.patch ];

  configureFlags = [
      "--prefix=${placeholder "out"}"
      #"--prefix=${out}"
      #"--target=x86_64-apple-darwin"
      "--with-libtapi=${libtapi-port}"
      #"--with-libxar=${xar.dev}"
      #"--disable-clang-as"
      #"--disable-lto-support"
    ];
  
  # Source is in a subdirectory, so we need to customize our phases:
  configurePhase = ''
    pushd cctools
    autoreconf -fi
    ./configure ${toString configureFlags}
    runHook postConfigure
    popd
  '';

  buildPhase = ''
    pushd cctools
    runHook preBuild
    make -j$NIX_BUILD_CORES
    runHook postBuild
    popd
  '';

  installPhase = ''
    pushd cctools
    runHook preInstall
    make install
    runHook postInstall
    popd
  '';

  meta = with lib; {
    description = ''
      Apple cctools and ld64 port for Linux, *BSD and macOS
    '';
    homepage = "https://github.com/tpoechtrager/cctools-port";
    license = licenses.apple-psl20;
    platforms = lib.platforms.unix;
    maintainers = with maintainers; [ joostn ];
  };
}