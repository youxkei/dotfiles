{ stdenv, fetchurl, autoPatchelfHook }:

stdenv.mkDerivation rec {
  pname = "libtree";
  version = "3.0.1";

  src = fetchurl {
    url = "https://github.com/haampie/libtree/releases/download/v${version}/libtree_x86_64";
    sha256 = "0a5vyi3p7c9ln2bbm646121hl43q9ihm1ykv8v189mddrysp7db4";
  };

  nativeBuildInputs = [ autoPatchelfHook ];

  unpackPhase = ":";

  installPhase = ''
    install -m755 -D $src $out/bin/libtree
  '';
}
