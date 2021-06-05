{ openssl, pkg-config, fetchFromGitHub, rustPlatform }:

rustPlatform.buildRustPackage rec {
  pname = "nicolive-comments";
  version = "0.3.0";

  src = fetchFromGitHub {
    owner = "youxkei";
    repo = pname;
    rev = "v${version}";
    sha256 = "06cmmd526al36yi4356v12k85xkfvdfjic0gc7bsgdhcazvma65v";
  };

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ openssl ];

  cargoSha256 = "0yj7acwwzz9qpvjxn1sjfvzgmz1qh12nfq8zxh4sxkjxf4jdp6br";
}
