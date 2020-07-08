{ fetchFromGitHub, rustPlatform }:

rustPlatform.buildRustPackage rec {
  pname = "teip";
  version = "1.2.0";

  src = fetchFromGitHub {
    owner = "greymd";
    repo = pname;
    rev = "v${version}";
    sha256 = "18x2dl7ysi4rzr6k21w9jzsvqvhfp934jcda12ai0hb7lfin4drx";
  };

  cargoSha256 = "13c2pdjzd49qznm1yj3rnli48267ajjdklrb1cpj0rhpirw4rh1j";
}
