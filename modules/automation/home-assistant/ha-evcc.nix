{
  lib,
  buildHomeAssistantComponent,
  fetchFromGitHub,
}:

buildHomeAssistantComponent rec {
  owner = "marq24";
  domain = "evcc_intg";
  version = "2026.1.1";

  src = fetchFromGitHub {
    owner = "marq24";
    repo = "ha-evcc";
    rev = version;
    hash = "sha256-8f0xJgC90yr6HHrm5OBF6LHlP5AUkVz5Ep9Wcfu9rtQ=";
  };

  meta = with lib; {
    description = "Home Assistant integration for evcc - Solar Charging";
    homepage = "https://github.com/marq24/ha-evcc";
    license = licenses.asl20;
  };
}
