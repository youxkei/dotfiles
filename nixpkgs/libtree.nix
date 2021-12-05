{ stdenv, fetchurl, autoPatchelfHook }:

stdenv.mkDerivation rec {
  pname = "libtree";
  version = "2.0.0";

  src = fetchurl {
    url = "https://github.com/haampie/libtree/releases/download/v${version}/libtree_x86_64";
    sha256 = "1268x1gkkqrn5r5f26kf0r9gddmdwh822mxxnnnhjq3pgxk4afs4";
  };

  nativeBuildInputs = [ autoPatchelfHook ];

  unpackPhase = ":";

  installPhase = ''
    install -m755 -D $src $out/bin/libtree
  '';
}
