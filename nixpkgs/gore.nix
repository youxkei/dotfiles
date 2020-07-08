{ buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "gore";
  version = "0.5.0";

  src = fetchFromGitHub {
    owner = "motemen";
    repo = pname;
    rev = "v${version}";
    sha256 = "0kiqf0a2fg6759byk8qbzidc9nx13rajd3f5bx09n19qbgfyflgb";
  };

  subPackages = ["cmd/gore"];

  vendorSha256 = "05jyfgpvsiiimphpqiv17dm0b65bnrljis93b2xxmrcj2aqvmfnx";
}
