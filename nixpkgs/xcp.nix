{ fetchFromGitHub, rustPlatform }:

rustPlatform.buildRustPackage rec {
  pname = "xcp";
  version = "0.9.0";

  src = fetchFromGitHub {
    owner = "tarka";
    repo = pname;
    rev = "v${version}";
    sha256 = "0ia1rj05fkvb7bgycx41c7aa3cki8j0xwn25kz47dswgpfl7a2rb";
  };

  cargoSha256 = "15v24ff9sgxnlj44hqbppsq8gz7irnpjszsvwq0pcbrsjc7qazwy";

  doCheck = false;
}
