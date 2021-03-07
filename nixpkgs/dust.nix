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

  cargoSha256 = "0karsf20yxcpjz4dvpb288kcn7mp1hzfsx38bj97fnxqlm0qhig0";
}
