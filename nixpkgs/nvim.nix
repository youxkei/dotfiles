{ stdenv, fetchurl }:

stdenv.mkDerivation rec {
  pname = "nvim";
  version = "v0.7.2";

  src = fetchurl {
    url = "https://github.com/neovim/neovim/releases/download/${version}/nvim.appimage";
    sha256 = "1qaqjr525dbj1icf0f82mf7qysrvv3m0c4sv32sx3dihqwhd1d9k";
  };

  unpackPhase = ":";

  dontStrip = true;

  installPhase = ''
    install -m755 -D $src $out/bin/nvim
  '';
}
