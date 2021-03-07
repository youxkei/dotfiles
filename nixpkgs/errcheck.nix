{ buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "errcheck";
  version = "1.6.0";

  src = fetchFromGitHub {
    owner = "kisielk";
    repo = pname;
    rev = "v${version}";
    sha256 = "17b1khy6lwy39qqkw0xj4s4wf58azd03kj5fa9jdf553rpcxzg1y";
  };

  vendorSha256 = "0mx506qb5sy6p4zqjs1n0w7dg8pz2wf982qi9v7nrhxysl2rlnxf";
}
