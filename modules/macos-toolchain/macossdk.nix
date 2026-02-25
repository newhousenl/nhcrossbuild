{ stdenv, fetchurl, lib }:

stdenv.mkDerivation rec {
  pname = "macossdk";
  version = "15.2";
  src = fetchurl {
    url = "https://github.com/joseluisq/macosx-sdks/releases/download/${version}/MacOSX${version}.sdk.tar.xz";
    hash = "sha256-sJCivWsFZmFtqL25qIq4ToQv0/RP9L5qPXlaWZ1GKg4=";
  };

  nativeBuildInputs = [ 
  ];

  unpackPhase = ''
    mkdir -p $out
    tar xfJ $src --strip-components=1 -C $out
  '';

  phases = [ "unpackPhase" ];
  meta = with lib; {
    description = ''
      macOS SDK
    '';
    homepage = "https://apple.com";
    license = licenses.unfree;
    platforms = platforms.all;
    maintainers = with maintainers; [ joostn ];
  };
}