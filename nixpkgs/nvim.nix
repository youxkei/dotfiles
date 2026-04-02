{ stdenv, fetchurl }:

stdenv.mkDerivation rec {
  pname = "nvim";
  version = "v0.12.0";

  src = fetchurl {
    url = "https://github.com/neovim/neovim/releases/download/${version}/nvim-linux-x86_64.appimage";
    hash = "sha256-eHa2dGKvCKvciEgYs5iz6CkH1qTInt/nxrH/Fo63xNY=";
  };

  unpackPhase = ":";

  dontStrip = true;

  installPhase = ''
    install -m755 -D $src $out/bin/nvim
  '';
}
