{ stdenv, fetchurl }:

stdenv.mkDerivation rec {
  pname = "nvim";
  version = "v0.9.1";

  src = fetchurl {
    url = "https://github.com/neovim/neovim/releases/download/${version}/nvim.appimage";
    hash = "sha256-JiiSF24h2gkCxPCx4CfVTSG0vK5rA5evzNioG0dsMFU=";
  };

  unpackPhase = ":";

  dontStrip = true;

  installPhase = ''
    install -m755 -D $src $out/bin/nvim
  '';
}
