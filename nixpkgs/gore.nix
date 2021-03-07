{ buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "gore";
  version = "0.5.2";

  src = fetchFromGitHub {
    owner = "motemen";
    repo = pname;
    rev = "v${version}";
    sha256 = "1fl9dmpcs1z45sqqjq1myk6smxi5rc52rxynjinay0xih2z9j9m2";
  };

  subPackages = ["cmd/gore"];

  vendorSha256 = "1il5r2wzf53rbid3ivq00198a95crvnw1lwbmlnsi0d7ryqvp4dw";
}
