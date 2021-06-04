{ openssl, pkg-config, fetchFromGitHub, rustPlatform }:

rustPlatform.buildRustPackage rec {
  pname = "nicolive-comments";
  version = "0.2.0";

  src = fetchFromGitHub {
    owner = "youxkei";
    repo = pname;
    rev = "v${version}";
    sha256 = "1rm9cz7002d21wj076xvjlbcrpzs0alqw1jdbvwvsfvn2bhw2ddb";
  };

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ openssl ];

  cargoSha256 = "1qdi8n88bpqybgngb1gs9i8zz1a2wlgyjrg7pwfajfv0vsmqn159";
}
