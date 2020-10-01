{ buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "errcheck";
  version = "1.4.0";

  src = fetchFromGitHub {
    owner = "kisielk";
    repo = pname;
    rev = "v${version}";
    sha256 = "00skyvy31yliw0f395j5h3gichi5n2q1m24izjidxvyc2av7pjn6";
  };

  vendorSha256 = "0mx506qb5sy6p4zqjs1n0w7dg8pz2wf982qi9v7nrhxysl2rlnxf";
}
