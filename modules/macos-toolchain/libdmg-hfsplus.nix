{ stdenv, fetchFromGitHub, cmake, lib, zlib }:

stdenv.mkDerivation rec {
  pname = "libdmg-hfsplus-dmgtool";
  version = "1.0.0";

  src = fetchFromGitHub {
    owner = "fanquake";
    repo = "libdmg-hfsplus";
    rev = "1cc791e4173da9cb0b0cc16c5a1aaa25d5eb5efa";
    sha256 = "sha256-FdpuRq6vmvM10RMILDVRYsDcu64ItKvjdfB4CmuU2UQ=";
  };

  nativeBuildInputs = [ 
    cmake 
    zlib
  ];

  meta = with lib; {
    description = ''
      Convert .iso images to .dmg. This is a stripped down version of planetbeing/libdmg-hfsplus.
      Usage: dmg path/to/.iso path/to/.dmg
    '';
    homepage = "https://github.com/fanquake/libdmg-hfsplus";
    license = licenses.gpl3Only;
    platforms = platforms.all;
    maintainers = with maintainers; [ joostn ];
  };
}