{ buildGoModule, fetchFromGitHub, pkg-config, libgit2 }:

buildGoModule rec {
  pname = "askgit";
  version = "0.2.0";

  src = fetchFromGitHub {
    owner = "augmentable-dev";
    repo = pname;
    rev = "v${version}";
    sha256 = "1kps0big3l393gll5q3v4z7ps6yq6iibjb255rv057l69bgmh8ds";
  };

  subPackages = ["."];

  nativeBuildInputs = [ pkg-config ];

  buildInputs = [ libgit2 ];

  buildFlags = ["-tags" "sqlite_vtable"];

  vendorSha256 = "0js261120nksqg64d2zhi87f8givb18ikp7kzbqrvygkqncbf7id";
}
