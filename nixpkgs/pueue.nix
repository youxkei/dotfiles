{ fetchFromGitHub, rustPlatform }:

rustPlatform.buildRustPackage rec {
  pname = "pueue";
  version = "0.12.1";

  src = fetchFromGitHub {
    owner = "Nukesor";
    repo = pname;
    rev = "v${version}";
    sha256 = "07ybkc7drxplnlkw414nv7a8vil230w8r94452c1x55kh7gqbhy1";
  };

  cargoSha256 = "1l74rp4grcd45l8dnc4jl69p68zzk414nqm7aqzv2sajffs668pd";
}
