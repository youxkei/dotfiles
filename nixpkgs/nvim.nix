{ stdenv, fetchurl }:

stdenv.mkDerivation rec {
  pname = "nvim";
  version = "v0.11.5";

  src = fetchurl {
    url = "https://github.com/neovim/neovim/releases/download/${version}/nvim-linux-x86_64.appimage";
    hash = "sha256-ekrfZX8Ld17k9N5slDU7SgVIo8azEEmiBTjgXU7qQRo=";
  };

  unpackPhase = ":";

  dontStrip = true;

  installPhase = ''
    install -m755 -D $src $out/bin/nvim
  '';
}
