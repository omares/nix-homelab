{
  lib,
  buildHomeAssistantComponent,
  fetchFromGitHub,
}:

buildHomeAssistantComponent rec {
  owner = "marq24";
  domain = "evcc_intg";
  version = "2026.10.7";

  src = fetchFromGitHub {
    owner = "marq24";
    repo = "ha-evcc";
    rev = version;
    hash = "sha256-638t1i+i+gBmsCGNHj61rhNMeS6Wcu7r7YX4w16YW04=";
  };

  meta = with lib; {
    description = "Home Assistant integration for evcc - Solar Charging";
    homepage = "https://github.com/marq24/ha-evcc";
    license = licenses.asl20;
  };
}
