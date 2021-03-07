{ buildGoModule, fetchFromGitHub, vim }:

buildGoModule rec {
  pname = "evans";
  version = "0.9.3";

  src = fetchFromGitHub {
    owner = "ktr0731";
    repo = pname;
    rev = version;
    sha256 = "1jy73737ah0qqy16ampx51cchrjrhkr945lpfnnshnalk86xdhdb";
  };

  doCheck = false;

  vendorSha256 = "1y98alg153p2djn7zxvpyiprdzpra2nxyga8qjark38hpfnnbm4y";
}
