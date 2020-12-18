{ buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "protoc-gen-grpc-gateway";
  version = "1.16.0";

  src = fetchFromGitHub {
    owner = "grpc-ecosystem";
    repo = "grpc-gateway";
    rev = "v${version}";
    sha256 = "0dzq1qbgzz2c6vnh8anx0j3py34sd72p35x6s2wrl001q68am5cc";
  };

  subPackages = ["protoc-gen-grpc-gateway"];

  vendorSha256 = "10rjk47qf3gidx8vwvzdp3mp3wrhl9gsaddfz2r5fgp3w7d9nlwd";
}
