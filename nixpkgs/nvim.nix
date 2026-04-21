{ stdenv, fetchurl }:

stdenv.mkDerivation rec {
  pname = "nvim";
  version = "v0.12.1";

  src = fetchurl {
    url = "https://github.com/neovim/neovim/releases/download/${version}/nvim-linux-x86_64.appimage";
    hash = "sha256-Ai5ufreZOYE/qJWtOap9yqELucIO0jTVdS/hKEXfJ9s=";
  };

  unpackPhase = ":";

  dontStrip = true;

  installPhase = ''
    install -m755 -D $src $out/bin/nvim
  '';
}
