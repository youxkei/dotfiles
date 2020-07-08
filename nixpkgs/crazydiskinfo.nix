{ stdenv, fetchFromGitHub, cmake, ncurses, libatasmart }:

stdenv.mkDerivation rec {
  pname = "crazydiskinfo";
  version = "1.0.2";

  src = fetchFromGitHub {
    owner = "otakuto";
    repo = pname;
    rev = version;
    sha256 = "04abwqpnwx2cq4x4c0bw27c4f4p52kznwzsqxsidk41j8ffya1h1";
  };

  patches = [ ./crazydiskinfo.patch ];

  buildInputs = [ ncurses libatasmart ];
  nativeBuildInputs = [ cmake ];
}
