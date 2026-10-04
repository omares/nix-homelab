{
  lib,
  buildHomeAssistantComponent,
  fetchFromGitHub,
  pystiebeleltron,
}:

buildHomeAssistantComponent rec {
  owner = "pail23";
  domain = "stiebel_eltron_isg";
  version = "2026.8";

  src = fetchFromGitHub {
    owner = "pail23";
    repo = "stiebel_eltron_isg_component";
    rev = version;
    hash = "sha256-fFD1UjKHV1Q6klJVmnD/LOnCA6w6560+vLboZ6SXBb8=";
  };

  dependencies = [ pystiebeleltron ];

  # manifest pins pystiebeleltron==0.6.3; everything it imports also exists in the nixpkgs version
  dontCheckManifest = true;

  meta = with lib; {
    description = "Stiebel Eltron ISG heat pump controller integration for Home Assistant";
    homepage = "https://github.com/pail23/stiebel_eltron_isg_component";
    license = licenses.mit;
  };
}
