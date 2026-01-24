{
  lib,
  buildHomeAssistantComponent,
  fetchFromGitHub,
}:
let
  version = "1.1.1";
in
buildHomeAssistantComponent {
  owner = "oliverwehrens";
  domain = "ostrom";
  inherit version;

  src = fetchFromGitHub {
    owner = "oliverwehrens";
    repo = "homeassistant_ostrom_integration";
    tag = version;
    hash = "sha256-Xqkcs8XXXp0qIzAi+tRqy44/rII6gTPrnKkJmNctpwI=";
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
