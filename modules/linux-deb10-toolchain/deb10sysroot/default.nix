{ stdenv, fetchurl }:

stdenv.mkDerivation {
  name = "deb10sysroot";

  src = fetchurl {
    url = "https://github.com/joostn/debian10/archive/refs/tags/1.0.tar.gz";
    hash = "sha256-5F1uC29yEOiIdsBLxeNM/PXKf/oX7sgBVkmiwkvodiI=";
  };

  phases = [ "unpackPhase"  ];

  unpackPhase = ''
    mkdir -p $out
    tar xfz $src -C $out --strip-components=1
    rm $out/lib/x86_64-linux-gnu/pkgconfig/expat.pc
    rm $out/usr/lib/x86_64-linux-gnu/libexpat*
    rm $out/usr/lib/x86_64-linux-gnu/libstdc++.*
    rm $out/usr/lib/gcc/x86_64-linux-gnu/8/libstdc++.*
    rm $out/usr/include/x86_64-linux-gnu/c++/8/bits/stdc++*
  '';
}