{ stdenv, fetchurl }:

stdenv.mkDerivation rec {
  pname = "tree";
  version = "v1.3.0";

  src = fetchurl {
    url = "https://github.com/peteretelej/tree/releases/download/${version}/tree-v1.3.0-Linux-amd64.tar.gz";
    hash = "sha256-xCVSfEYJW0JfGSvkv3JYYTORJcy5RgGE70kO9KBaqxo=";
  };

  sourceRoot = ".";

  installPhase = ''
    install -m755 -D tree $out/bin/tree
  '';
}

