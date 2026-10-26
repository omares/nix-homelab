{
  lib,
  buildHomeAssistantComponent,
  fetchFromGitHub,
  pycryptodomex,
  defusedxml,
  babel,
}:
let
  version = "1.27.0";
in
buildHomeAssistantComponent {
  owner = "alexhass";
  domain = "syr_connect";
  inherit version;

  src = fetchFromGitHub {
    owner = "alexhass";
    repo = "syr_connect";
    rev = "v${version}";
    hash = "sha256-yDHUK/JBWULR4YHdCa29wnCOkOJ1pzzk+AkfxRHJAys=";
  };

  dependencies = [
    pycryptodomex
    defusedxml
    babel
  ];

  # manifest pins upper bounds that do not match nixpkgs versions and omits babel
  dontCheckManifest = true;

  meta = with lib; {
    description = "Home Assistant integration for SYR Connect water softeners";
    homepage = "https://github.com/alexhass/syr_connect";
    license = licenses.mit;
  };
}
