{
  lib,
  buildHomeAssistantComponent,
  fetchFromGitHub,
}:

buildHomeAssistantComponent rec {
  owner = "krahabb";
  domain = "meross_lan";
  version = "5.7.1";

  src = fetchFromGitHub {
    owner = "krahabb";
    repo = "meross_lan";
    rev = "v${version}";
    hash = "sha256-JR67bUl1rJcw0CXKiYezS8sR9unj/wZSox1Cq04EuCw=";
  };

  meta = with lib; {
    description = "Meross LAN integration for Home Assistant";
    homepage = "https://github.com/krahabb/meross_lan";
    license = licenses.mit;
  };
}
