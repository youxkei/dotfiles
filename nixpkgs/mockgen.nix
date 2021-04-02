{ buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "mockgen";
  version = "1.5.0";

  src = fetchFromGitHub {
    owner = "golang";
    repo = "mock";
    rev = "v${version}";
    sha256 = "12l7p08pwwk3xn70w7rlm28nz6jf4szlzgjxjfmbssyirxxxy8v1";
  };

  subPackages = ["mockgen"];

  doCheck = false;

  vendorSha256 = "0k4q8hdx909r22hj58zm4aa68z3dpllx43m63cia8ycj4gp1mgkh";
}
