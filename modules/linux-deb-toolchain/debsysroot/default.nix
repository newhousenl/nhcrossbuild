{ stdenv, fetchurl, lib, dpkg, debianversion ? 10, arch ? "amd64" }:

let
  pkgsData = builtins.fromJSON (builtins.readFile (./. + "/pkgs-deb${toString debianversion}-${arch}.json"));

  debPackages = map (pkg: fetchurl {
    inherit (pkg) url;
    name = pkg.name + ".deb";
    hash = pkg.sha256;
  }) pkgsData;

in
stdenv.mkDerivation {
  pname = "debsysroot";
  version = toString debianversion;

  nativeBuildInputs = [ dpkg ];

  dontUnpack = true;

  installPhase = ''
    mkdir -p $out
    for deb in ${lib.concatStringsSep " " debPackages}; do
      dpkg-deb -x $deb $out
    done


    # Cleanup and symlink handling
    pushd $out

    # Remove absolute symlinks and replace with relative ones
    find . -type l | while read link; do
      target=$(readlink "$link")
      if [[ "$target" == /* ]]; then
        rel_target=$(realpath --relative-to="$(dirname "$link")" "$out$target")
        if [[ -e "$(dirname "$link")/$rel_target" ]]; then
          ln -sf "$rel_target" "$link"
        else
          # If it's still missing, don't worry, but Nix stdenv might complain
          # if it's a broken symlink in some checks.
          # We'll keep it for now or delete it if Nix checkPhase fails.
          rm "$link"
        fi
      fi
    done

    # Prune empty directories
    find . -type d -empty -delete

    popd
  '';

  # Disable some Nix checks that fail on Debian's messy sysroot structure
  # especially the "no broken symlinks" check which is very strict.
  # Also disable stripping as it's not our binaries.
  dontFixup = true;

  meta = with lib; {
    description = "Debian ${toString debianversion} sysroot for cross-compilation";
  };
}
