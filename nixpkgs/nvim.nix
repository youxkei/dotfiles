{ stdenv, fetchurl }:

stdenv.mkDerivation rec {
  pname = "nvim";
  version = "v0.9.0";

  src = fetchurl {
    url = "https://github.com/neovim/neovim/releases/download/${version}/nvim.appimage";
    hash = "sha256-Dh5tU8bIBV3iO9sz9gu2SvC68ROQZpwbQOy78sejRUc=";
  };

  unpackPhase = ":";

  dontStrip = true;

  installPhase = ''
    install -m755 -D $src $out/bin/nvim
  '';
}
