{ buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "evans";
  version = "0.9.0";

  src = fetchFromGitHub {
    owner = "ktr0731";
    repo = pname;
    rev = version;
    sha256 = "10kfb4vaysdblbf8cri1wvkb1shlgaqw8ka6g0q9cj7bbk4axwf2";
  };

  vendorSha256 = "1yiqrpmvmr3w3f7wzrflm53h06w3547ds13kf1n680fy9r23msbc";
}
