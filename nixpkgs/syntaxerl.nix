{ stdenv, rebar3, fetchFromGitHub }:

stdenv.mkDerivation rec {
  pname = "syntaxerl";
  version = "0.15.0";

  src = fetchFromGitHub {
    owner = "ten0s";
    repo  = pname;
    rev = version;
    sha256 = "0b8h33vf5x40j0har0686nhf0vs5pna7d4z8awvrai1a8aldk5nz";
  };

  buildInputs = [ rebar3 ];

  buildPhase = "rebar3 escriptize";

  installPhase = ''
    mkdir -p $out/bin
    cp _build/default/bin/syntaxerl $out/bin
  '';
}
