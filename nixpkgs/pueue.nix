{ fetchFromGitHub, rustPlatform }:

rustPlatform.buildRustPackage rec {
  pname = "pueue";
  version = "0.12.0";

  src = fetchFromGitHub {
    owner = "Nukesor";
    repo = pname;
    rev = "v${version}";
    sha256 = "13l4czb0s0awww6hi8m98a9awwk0rc25gl08cpwqsighmw71brf8";
  };

  cargoSha256 = "04wa2lv4i765q3v6ihr0sgkzl4z1mmc0jx9pd1jk0ngii3qcka77";
}
