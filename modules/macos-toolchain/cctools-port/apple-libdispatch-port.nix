{ clangStdenv, fetchFromGitHub, cmake, lib }:

clangStdenv.mkDerivation rec {
  pname = "apple-libdispatch-port";
  version = "6.0.3";

  src = fetchFromGitHub {
    owner = "tpoechtrager";
    repo = "apple-libdispatch";
    #rev = "fdf3fc85a9557635668c78801d79f10161d83f12";
    #sha256 = "sha256-YQjYjBYRObRPgcRZgm5R2RFsuT6P2KBzWzJ3nB70Jk8=";
    rev = "323b9b4e0ca05d6c56a0c2f2d7d8d47363e612b7";
    hash = "sha256-qcwvxxEhRM4GslQyzvl+9GVQTEUyffkde3cZRvfWgdw=";
  };

  nativeBuildInputs = [ 
    cmake 
  ];

  meta = with lib; {
    description = ''
      Linux port of libdispatch (Grand Central Dispatch)
    '';
    homepage = "https://github.com/tpoechtrager/apple-libdispatch";
    license = licenses.asl20;
    platforms = lib.platforms.unix;
    maintainers = with maintainers; [ joostn ];
  };
}