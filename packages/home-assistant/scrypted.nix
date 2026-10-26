{
  lib,
  buildHomeAssistantComponent,
  fetchFromGitHub,
  buildPythonPackage,
  fetchPypi,
  aiodns,
  aiohttp,
  python-engineio,
}:
let
  # The sdist generates its sources at build time from the scrypted repo, use the wheel
  scrypted-sdk = buildPythonPackage rec {
    pname = "scrypted-sdk";
    version = "0.1.1";
    format = "wheel";

    src = fetchPypi {
      pname = "scrypted_sdk";
      inherit version;
      format = "wheel";
      dist = "py3";
      python = "py3";
      hash = "sha256-3LhVaf2JM+baVcJlQtv0vIClcodSnicOssbddonjGiA=";
    };

    dependencies = [
      aiodns
      aiohttp
      python-engineio
    ]
    ++ python-engineio.optional-dependencies.asyncio_client;

    pythonImportsCheck = [ "scrypted_sdk" ];

    meta = {
      description = "Python client for the Scrypted RPC API";
      homepage = "https://github.com/koush/scrypted";
      license = lib.licenses.isc;
    };
  };
in
buildHomeAssistantComponent {
  owner = "koush";
  domain = "scrypted";
  # No releases upstream, HACS installs main
  version = "0.1.0-unstable-2026-10-19";

  src = fetchFromGitHub {
    owner = "koush";
    repo = "ha_scrypted";
    rev = "f67c504645f8b8a2fd0829858bdc507eef985d5a";
    hash = "sha256-51J896ZesyPx8lXxOVXgEOsA1Hl1P/KyJLx/LCyRD5s=";
  };

  dependencies = [ scrypted-sdk ];

  meta = with lib; {
    description = "Scrypted Custom Component for Home Assistant";
    homepage = "https://github.com/koush/ha_scrypted";
    license = licenses.mit;
  };
}
