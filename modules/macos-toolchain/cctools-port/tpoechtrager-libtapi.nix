{
  lib,
  clangStdenv,
  fetchFromGitHub,
  fetchpatch,
  cmake,
  ninja,
  python3,
  zlib,
  bash,
  coreutils
}:

clangStdenv.mkDerivation (finalAttrs: {
  pname = "tpoechtrager-libtapi";
  version = "1300.6.5";

  src = fetchFromGitHub {
    owner = "tpoechtrager";
    repo = "apple-libtapi";
    rev = "54c9044082ba35bdb2b0edf282ba1a340096154c";
    hash = "sha256-4JwND6o9hqcdtxlEnzLJK/t41nzXTRbQhMgIr8/ZEo4=";
  };

  buildInputs = [ zlib ]; # Upstream links against zlib in their distribution.

  nativeBuildInputs = [
    cmake
    ninja
    bash
    python3
    coreutils
  ];

  configurePhase = ":";

  buildPhase = ''
    runHook preBuild
    # set JOBS explicitly, so we don't need to run tools/cpucount/get_cpu_count.sh (which fails on nix due to the shebang)
    export JOBS=$(nproc)
    echo "JOBS=$JOBS"
    INSTALLPREFIX=$out bash ./build.sh
    bash ./install.sh
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    export JOBS=$(nproc)
    echo "JOBS=$JOBS"
    bash ./install.sh
    runHook postInstall
  '';
})