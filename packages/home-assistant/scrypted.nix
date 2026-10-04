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
    rev = "eb1f6de0be8f116023e62d3440615c6b4161f502";
    hash = "sha256-zJpbwLSDioEMm0YVJizec1JDY49GRq0to69Q1nncWB8=";
  };

  meta = with lib; {
    description = "Scrypted Custom Component for Home Assistant";
    homepage = "https://github.com/koush/ha_scrypted";
    license = licenses.mit;
  };
}
