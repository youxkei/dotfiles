{ fetchFromGitHub, rustPlatform }:

rustPlatform.buildRustPackage rec {
  pname = "xcp";
  version = "0.7.3";

  src = fetchFromGitHub {
    owner = "tarka";
    repo = pname;
    rev = "v${version}";
    sha256 = "025h7439yl12aisd5aba7v2v1axhifgmr3cwcmx7n721xc7zpgvi";
  };

  cargoSha256 = "0ayamxkrkiyqnnhir2zms0bb5kdgg9vrx7x0n75i8hwb55fjlfcl";

  doCheck = false;
}
