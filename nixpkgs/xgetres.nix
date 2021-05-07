{ stdenv, fetchFromGitHub, xorg }:

stdenv.mkDerivation rec {
  pname = "xgetres";
  version = "1.0";

  src = fetchFromGitHub {
    owner = "tamirzb";
    repo  = pname;
    rev = version;
    sha256 = "04cnv8im6sjgrmpcp6qsj73wqk4pql95ja7s3p8f3h3jrsgrvbv8";
  };

  buildInputs = [xorg.libX11];

  installPhase = ''
    make install PREFIX=$out
  '';
}
