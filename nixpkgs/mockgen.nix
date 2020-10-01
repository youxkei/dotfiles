{ buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "mockgen";
  version = "1.4.4";

  src = fetchFromGitHub {
    owner = "golang";
    repo = "mock";
    rev = "v${version}";
    sha256 = "1lj0dvd6div4jaq1s0afpwqaq9ah8cxhkq93wii2ably1xmp2l0a";
  };

  subPackages = ["mockgen"];

  doCheck = false;

  vendorSha256 = "1md4cg1zzhc276sc7i2v0xvg5pf6gzy0n9ga2g1lx3d572igq1wy";
}
