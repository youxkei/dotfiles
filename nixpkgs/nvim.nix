{ stdenv, fetchurl }:

stdenv.mkDerivation rec {
  pname = "nvim";
  version = "v0.11.2";

  src = fetchurl {
    url = "https://github.com/neovim/neovim/releases/download/${version}/nvim-linux-x86_64.appimage";
    hash = "sha256-x8Nl/fZR8Fiy/BU9ZntAasOcpnSlSqn3mVRLyMKN2Jg=";
  };

  unpackPhase = ":";

  dontStrip = true;

  installPhase = ''
    install -m755 -D $src $out/bin/nvim
  '';
}
