{ stdenv, fetchurl, lib, p7zip, msitools }:

#https://aka.ms/vs/17/release/channel

# Doesn't work for PTGui unfortunately. This installs the Windows SDK and ucrt, but we still need a crt.
# The MSVC crt is included with MSVC only. It can be obtained from  https://github.com/Jake-Shadle/xwin
# or from a visual studio installation. Both methods will not work inside a nix derivation.

stdenv.mkDerivation rec {
  pname = "windowssdk";
  majorversion = "26100";
  version = "${majorversion}.3037.250123-2219";
  src = fetchurl {
    url = "https://go.microsoft.com/fwlink/?linkid=2301948";
    hash = "sha256-+5tHZX2kMl5V1RmOAfKErG+rT0WsIxrM0Hm1vlLA5as=";
  };

  nativeBuildInputs = [ 
    p7zip msitools
  ];

  unpackPhase = ''
    mkdir -p $out

    casesensitive=1
    touch $out/UPPERCASE
    if [[ -f $out/uppercase ]]; then
      echo "File system is case insensitive!"
      casesensitive=0
    fi
    rm $out/UPPERCASE

    ln -s "$src" disk.iso
    7z x disk.iso -o./extracted_iso

    for f in ./extracted_iso/Installers/*.msi; do
      echo "Extracting $f"
      msiextract "$f"
    done

    mkdir -p $out/include
    mkdir -p $out/lib
    cp -a ./Program\ Files/Windows\ Kits/10/Include/10.0.${majorversion}.0/* $out/include/
    cp -a ./Program\ Files/Windows\ Kits/10/Lib/10.0.${majorversion}.0/* $out/lib/

    #cp -a ./Program\ Files $out/
    #cp -a ./extracted_iso $out/

    if [[ $casesensitive -eq 1 ]]; then
      cd $out
      ls -al
      bash ${./windowssdk_symlinks.sh}
    fi
  '';

  phases = [ "unpackPhase" ];
  meta = with lib; {
    description = ''
      MS Windows SDK
    '';
    homepage = "https://microsoft.com";
    license = licenses.unfree;
    platforms = lib.platforms.unix;
    maintainers = with maintainers; [ joostn ];
  };
}