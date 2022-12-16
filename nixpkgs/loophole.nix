{ buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "loophole";
  version = "1.0.0-beta.15";

  src = fetchFromGitHub {
    owner = pname;
    repo = "cli";
    rev = "${version}";
    hash = "sha256-O5FdClqN9A88Up9iHoZTD6fiG9d7aHLFTwaR00mOiuM=";
  };

  vendorHash = "sha256-znKbjiNRpS3zqHYpfES6tN8WOTTrsy2qZKGEiBFoIzg=";
  subPackages = ["."];

  installPhase = ''
    runHook preInstall
    install -D $GOPATH/bin/cli $out/bin/loophole
    runHook postInstall
  '';}
