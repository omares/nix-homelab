{
  lib,
  buildHomeAssistantComponent,
  fetchFromGitHub,
}:

buildHomeAssistantComponent rec {
  owner = "Clooos";
  domain = "bubble_card_tools";
  version = "1.0.0";

  src = fetchFromGitHub {
    owner = "Clooos";
    repo = "Bubble-Card-Tools";
    rev = "v${version}";
    hash = "sha256-vaEL4Exfv8rlM/9tYQIPfxdQnlvfUcHA8ZxbYocKHas=";
  };

  meta = with lib; {
    description = "Bubble Card Tools - Backend integration for Bubble Card modules";
    homepage = "https://github.com/Clooos/Bubble-Card-Tools";
    license = licenses.mit;
  };
}
