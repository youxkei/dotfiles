{ buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "tts";
  version = "0.2.0";

  src = fetchFromGitHub {
    owner = "youxkei";
    repo = pname;
    rev = "v${version}";
    sha256 = "0zkq7873z2rvkvf18khaqmk9rqms66m3mx2m5xi497svjmxqmq98";
  };

  vendorSha256 = "1w553dw3glzybcxg0pjfbv4zfxygj853c5g5wf8mliajw8ndrjfd";
}
