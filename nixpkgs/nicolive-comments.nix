{ openssl, pkg-config, fetchFromGitHub, rustPlatform }:

rustPlatform.buildRustPackage rec {
  pname = "nicolive-comments";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "youxkei";
    repo = pname;
    rev = "v${version}";
    sha256 = "1qbr4fs62i978wh9wjshx9zi29jyinzdfl882vi9h74bn8472lf8";
  };

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ openssl ];

  cargoSha256 = "0yc4wp01kdnc7bvnws0pzzfg8v23mi6flw294a6vlhydhs8rg2rq";
}
