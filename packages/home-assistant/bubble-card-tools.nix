{
  lib,
  buildHomeAssistantComponent,
  fetchFromGitHub,
}:

buildHomeAssistantComponent rec {
  owner = "Clooos";
  domain = "bubble_card_tools";
  version = "1.1.1";

  src = fetchFromGitHub {
    owner = "Clooos";
    repo = "Bubble-Card-Tools";
    rev = "v${version}";
    hash = "sha256-It74yOhvPaLE81eb6JGir4NWRe+wIi1woapx6EoOEf0=";
  };

  meta = with lib; {
    description = "Bubble Card Tools - Backend integration for Bubble Card modules";
    homepage = "https://github.com/Clooos/Bubble-Card-Tools";
    license = licenses.mit;
  };
}
