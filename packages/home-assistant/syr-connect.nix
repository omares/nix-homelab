{
  lib,
  buildHomeAssistantComponent,
  fetchFromGitHub,
  pycryptodomex,
  defusedxml,
}:
let
  version = "1.26.0";
in
buildHomeAssistantComponent {
  owner = "alexhass";
  domain = "syr_connect";
  inherit version;

  src = fetchFromGitHub {
    owner = "alexhass";
    repo = "syr_connect";
    rev = "v${version}";
    hash = "sha256-B2ComFtSPwtpYJjzJI2Q4P5a+6rDqN9j0W/wsXHmlkU=";
  };

  dependencies = [
    pycryptodomex
    defusedxml
  ];

  # manifest pins upper bounds that do not match nixpkgs versions
  dontCheckManifest = true;

  meta = with lib; {
    description = "Home Assistant integration for SYR Connect water softeners";
    homepage = "https://github.com/alexhass/syr_connect";
    license = licenses.mit;
  };
}
