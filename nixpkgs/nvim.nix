{ stdenv, fetchurl }:

stdenv.mkDerivation rec {
  pname = "nvim";
  version = "v0.10.1";

  src = fetchurl {
    url = "https://github.com/neovim/neovim/releases/download/${version}/nvim.appimage";
    hash = "sha256-xHYtVMrf2fpEl8eWkZeALJz54Nkmw55WHwvRcONsiqA=";
  };

  unpackPhase = ":";

  dontStrip = true;

  installPhase = ''
    install -m755 -D $src $out/bin/nvim
  '';
}
