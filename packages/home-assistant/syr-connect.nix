{
  lib,
  buildHomeAssistantComponent,
  fetchFromGitHub,
  pycryptodomex,
}:
let
  version = "1.0.8";
in
buildHomeAssistantComponent {
  owner = "alexhass";
  domain = "syr_connect";
  inherit version;

  src = fetchFromGitHub {
    owner = "alexhass";
    repo = "syr_connect";
    rev = "v${version}";
    hash = "sha256-vW7AjNJeqxRagd+tUSbtTyUXa564td8HdHf93/j4ERA=";
  };

  dependencies = [ pycryptodomex ];

  # nixpkgs has pycryptodomex 3.23.0, manifest requires 3.19.0
  dontCheckManifest = true;

  meta = with lib; {
    description = "Home Assistant integration for SYR Connect water softeners";
    homepage = "https://github.com/alexhass/syr_connect";
    license = licenses.mit;
  };
}
