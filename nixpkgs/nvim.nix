{ stdenv, fetchurl }:

stdenv.mkDerivation rec {
  pname = "nvim";
  version = "v0.9.2";

  src = fetchurl {
    url = "https://github.com/neovim/neovim/releases/download/${version}/nvim.appimage";
    hash = "sha256-YZUBMeGBV6ucfxQTGj3aCqgfjk+0eZS/bYtBjZvm48A=";
  };

  unpackPhase = ":";

  dontStrip = true;

  installPhase = ''
    install -m755 -D $src $out/bin/nvim
  '';
}
