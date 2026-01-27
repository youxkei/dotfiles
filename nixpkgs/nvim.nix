{ stdenv, fetchurl }:

stdenv.mkDerivation rec {
  pname = "nvim";
  version = "v0.11.6";

  src = fetchurl {
    url = "https://github.com/neovim/neovim/releases/download/${version}/nvim-linux-x86_64.appimage";
    hash = "sha256-d90W2G5lSaC7u/vBhjbUNP/lsKyLmFSnZp41zEuT3aA=";
  };

  unpackPhase = ":";

  dontStrip = true;

  installPhase = ''
    install -m755 -D $src $out/bin/nvim
  '';
}
