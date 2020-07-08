{ stdenv, rebar3, fetchFromGitHub }:

stdenv.mkDerivation rec {
  pname = "syntaxerl";
  version = "0.14.0";

  src = fetchFromGitHub {
    owner = "ten0s";
    repo  = pname;
    rev = version;
    sha256 = "07x74kbf48p31ighdlwwykgbmgj8vai0hv3sbs1iwbqq6yw8lhg9";
  };

  buildInputs = [ rebar3 ];

  buildPhase = "rebar3 escriptize";

  installPhase = ''
    mkdir -p $out/bin
    cp _build/default/bin/syntaxerl $out/bin
  '';
}
