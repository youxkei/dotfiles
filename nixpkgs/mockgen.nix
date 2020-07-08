{ buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "mockgen";
  version = "1.4.3";

  src = fetchFromGitHub {
    owner = "golang";
    repo = "mock";
    rev = "v${version}";
    sha256 = "1p37xnja1dgq5ykx24n7wincwz2gahjh71b95p8vpw7ss2g8j8wx";
  };

  subPackages = ["mockgen"];

  vendorSha256 = "1kpiij3pimwv3gn28rbrdvlw9q5c76lzw6zpa12q6pgck76acdw4";
}
