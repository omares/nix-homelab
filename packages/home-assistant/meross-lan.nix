{
  lib,
  buildHomeAssistantComponent,
  fetchFromGitHub,
}:

buildHomeAssistantComponent rec {
  owner = "krahabb";
  domain = "meross_lan";
  version = "5.8.0";

  src = fetchFromGitHub {
    owner = "krahabb";
    repo = "meross_lan";
    rev = "v${version}";
    hash = "sha256-Ru/YmoCJPmnnrIGls87vmEo44+FxcUXi0MSYg+Jvdz0=";
  };

  meta = with lib; {
    description = "Meross LAN integration for Home Assistant";
    homepage = "https://github.com/krahabb/meross_lan";
    license = licenses.mit;
  };
}
