{ buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "wire";
  version = "0.5.0";

  src = fetchFromGitHub {
    owner = "google";
    repo = pname;
    rev = "v${version}";
    sha256 = "038c7ss7fgihh76b4lnsm7dhhhq4kjwm06f8radw454g5jdg467p";
  };

  subPackages = ["cmd/wire"];

  vendorSha256 = "0mzln840gk146j1y1ir9agswyzvaik6hyy7z06lfxd8gp3h1fmb4";
}
