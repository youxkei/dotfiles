{ buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "countdown";
  version = "1.0.0";

  src = fetchFromGitHub {
    owner = "antonmedv";
    repo = pname;
    rev = "v${version}";
    sha256 = "0pdaw1krr0bsl4amhwx03v2b02iznvwvqn7af5zp4fkzjaj14cdw";
  };

  vendorSha256 = "0p8gy271zfkjzksr9fm886zs4yh60cqgihag51pgj5k7fxw7rmcs";
}
