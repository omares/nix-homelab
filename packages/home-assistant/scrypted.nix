{
  lib,
  buildHomeAssistantComponent,
  fetchFromGitHub,
}:
let
  version = "0.0.10";
in
buildHomeAssistantComponent {
  owner = "koush";
  domain = "scrypted";
  inherit version;

  src = fetchFromGitHub {
    owner = "koush";
    repo = "ha_scrypted";
    rev = "main";
    hash = "sha256-A7vx7aXnmCMztKRUScmWqwBxpFGSVe3DVia3LGxpvkU=";
  };

  meta = with lib; {
    description = "Scrypted Custom Component for Home Assistant";
    homepage = "https://github.com/koush/ha_scrypted";
    license = licenses.mit;
  };
}
