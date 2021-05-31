{ buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "tts";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "youxkei";
    repo = pname;
    rev = "v${version}";
    sha256 = "033kvygim2y26r9id8b7sv86d1nxaih43r7zpq7916p89c7ll0jr";
  };

  vendorSha256 = "1cilmskip173x9zg8389a0200r6hq4kfg1kvfyy1wdqpxknjwp1r";
}
