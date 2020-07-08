{ buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "wire";
  version = "0.4.0";

  src = fetchFromGitHub {
    owner = "google";
    repo = pname;
    rev = "v${version}";
    sha256 = "1z3nrccxsrhphpb6yrmc1hn4njy8qbayg3w6m9zsbi77yaiigxni";
  };

  subPackages = ["cmd/wire"];

  vendorSha256 = "0mzln840gk146j1y1ir9agswyzvaik6hyy7z06lfxd8gp3h1fmb4";
}
