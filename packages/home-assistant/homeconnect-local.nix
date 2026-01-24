{
  lib,
  buildHomeAssistantComponent,
  fetchFromGitHub,
  buildPythonPackage,
  fetchPypi,
  setuptools,
  versioningit,
  aiohttp,
  xmltodict,
  pycryptodome,
}:
let
  websocketVersion = "1.4.5";
  homeconnect-websocket = buildPythonPackage {
    pname = "homeconnect-websocket";
    version = websocketVersion;
    pyproject = true;

    src = fetchPypi {
      pname = "homeconnect_websocket";
      version = websocketVersion;
      hash = "sha256-TFI8rEqyRSQkPJEL6N4OMq9gP8AwMlR7yp6KMdWzRT8=";
    };

    build-system = [
      setuptools
      versioningit
    ];

    dependencies = [
      aiohttp
      xmltodict
      pycryptodome
    ];

    doCheck = false;

    pythonImportsCheck = [ "homeconnect_websocket" ];

    meta = with lib; {
      description = "Python library for local communication with Home Connect appliances";
      homepage = "https://github.com/chris-mc1/homeconnect-websocket";
      license = licenses.mit;
    };
  };

  version = "1.0.4";
in
buildHomeAssistantComponent {
  owner = "chris-mc1";
  domain = "homeconnect_ws";
  inherit version;

  src = fetchFromGitHub {
    owner = "chris-mc1";
    repo = "homeconnect_local_hass";
    rev = version;
    hash = "sha256-MJ6Yx2HUSueSNiyOgVrA57OBekgxwmfFx4exNIdPjvk=";
  };

  dependencies = [ homeconnect-websocket ];

  # Using newer homeconnect-websocket than manifest specifies
  dontCheckManifest = true;

  meta = with lib; {
    description = "Home Connect Local integration for Home Assistant using direct communication over the local network";
    homepage = "https://github.com/chris-mc1/homeconnect_local_hass";
    license = licenses.mit;
  };
}
