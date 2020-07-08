{ buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "gitqlite";
  version = "0.0.1";

  src = fetchFromGitHub {
    owner = "augmentable-dev";
    repo = pname;
    rev = "v${version}";
    sha256 = "1arb0w26wnhpqk15dk42fgynjksa0s3cmp6flc8zph0zkw1nslvh";
  };

  vendorSha256 = "0dmry4pi0k3aqmclnn5c354p210w217947js57xr9qj8v8g0f9iz";
}
