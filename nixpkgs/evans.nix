{ buildGoModule, fetchFromGitHub, vim }:

buildGoModule rec {
  pname = "evans";
  version = "0.9.1";

  src = fetchFromGitHub {
    owner = "ktr0731";
    repo = pname;
    rev = version;
    sha256 = "0nyzgaw3igki6scxsxmjv0wb2m1fjz58fz7nfa5y1w0vwjs0fhvy";
  };

  doCheck = false;

  vendorSha256 = "11yvsfj3kkwm0z17695rmycvgdgfrc8dnd41r1z0430zv6x67b9f";
}
