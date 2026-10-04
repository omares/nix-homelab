{
  lib,
  buildHomeAssistantComponent,
  fetchFromGitHub,
}:
let
  version = "1.3";
in
buildHomeAssistantComponent {
  owner = "oliverwehrens";
  domain = "ostrom";
  inherit version;

  src = fetchFromGitHub {
    owner = "oliverwehrens";
    repo = "homeassistant_ostrom_integration";
    tag = version;
    hash = "sha256-azvRMFiYGGZb7xWZi5nHRTiL83u9TA/lbdP+blfyfLk=";
  };

  # requests is already a dependency of Home Assistant
  dependencies = [ ];

  dontCheckManifest = true;

  meta = {
    description = "Home Assistant integration for Ostrom energy provider (dynamic electricity prices)";
    homepage = "https://github.com/oliverwehrens/homeassistant_ostrom_integration";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ ];
  };
}
