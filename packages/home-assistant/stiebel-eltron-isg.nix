{
  lib,
  buildHomeAssistantComponent,
  fetchFromGitHub,
  pystiebeleltron,
}:

buildHomeAssistantComponent rec {
  owner = "pail23";
  domain = "stiebel_eltron_isg";
  version = "2026.2";

  src = fetchFromGitHub {
    owner = "pail23";
    repo = "stiebel_eltron_isg_component";
    rev = version;
    hash = "sha256-t7SdG50QidWJOspu9QqAyw3tuL1hKA97A565fntG9dM=";
  };

  dependencies = [ pystiebeleltron ];

  meta = with lib; {
    description = "Stiebel Eltron ISG heat pump controller integration for Home Assistant";
    homepage = "https://github.com/pail23/stiebel_eltron_isg_component";
    license = licenses.mit;
  };
}
