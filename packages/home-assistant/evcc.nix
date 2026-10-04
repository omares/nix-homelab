{
  lib,
  buildHomeAssistantComponent,
  fetchFromGitHub,
}:

buildHomeAssistantComponent rec {
  owner = "marq24";
  domain = "evcc_intg";
  version = "2026.10.0";

  src = fetchFromGitHub {
    owner = "marq24";
    repo = "ha-evcc";
    rev = version;
    hash = "sha256-+H/P5ZQWZ/07DTjBJCDIOaaylpDABX6HpHNZ+q/NGr8=";
  };

  meta = with lib; {
    description = "Home Assistant integration for evcc - Solar Charging";
    homepage = "https://github.com/marq24/ha-evcc";
    license = licenses.asl20;
  };
}
