{ fetchFromGitHub, rustPlatform }:

rustPlatform.buildRustPackage rec {
  pname = "dust";
  version = "0.5.4";

  src = fetchFromGitHub {
    owner = "bootandy";
    repo = pname;
    rev = "v${version}";
    sha256 = "15737dv26r73j0xg071v6dbkncvggp3kwx1gqym5qmrh4zb9l097";
  };

  doCheck = false;

  cargoSha256 = "0ciwaynpyy8qg08zqw977qzb31nqvkkhv5swngigdq6s5b9l79m3";
}
