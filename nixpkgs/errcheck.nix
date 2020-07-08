{ buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "errcheck";
  version = "1.3.0";

  src = fetchFromGitHub {
    owner = "kisielk";
    repo = pname;
    rev = "v${version}";
    sha256 = "0d0hqqv85csscj2x76c9nxafs9y8xhfwd2cjq586bvwmyc82c1r0";
  };

  vendorSha256 = "0mx506qb5sy6p4zqjs1n0w7dg8pz2wf982qi9v7nrhxysl2rlnxf";
}
