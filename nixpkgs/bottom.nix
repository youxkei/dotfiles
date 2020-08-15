{ fetchFromGitHub, rustPlatform }:

rustPlatform.buildRustPackage rec {
  pname = "bottom";
  version = "0.4.5";

  src = fetchFromGitHub {
    owner = "ClementTsang";
    repo = pname;
    rev = version;
    sha256 = "0vj113j9cn62p8q624lgamj7gyvzpdwnnyhhrp04mampndqfd46p";
  };

  cargoSha256 = "1mndc8q26p0z97cxj87naxcaw1xpmayr9z7mj3dqdrd1d034ks10";

  doCheck = false;
}
