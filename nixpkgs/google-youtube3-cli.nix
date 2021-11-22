with import <nixpkgs>{};

{ fetchFromGitHub, rustPlatform }:

rustPlatform.buildRustPackage rec {
  pname = "google-youtube3-cli";
  version = "2.0.4+20210330";

  src = fetchCrate {
    inherit pname version;
    sha256 = "1ibrcn0qrxk45svrif982kabvyah7wnkxfdfya8q9npig918g31g";
  };

  cargoSha256 = "05044d2z9mbiki9m04jml3x0w3011ymah2glwh1zpqnjr434v1i7";
}
