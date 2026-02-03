{
  lib,
  stdenv,
  fetchFromGitHub,
  yarn-berry_4,
  nodejs,
}:

let
  yarn-berry = yarn-berry_4;
in

stdenv.mkDerivation (finalAttrs: {
  pname = "lovelace-horizon-card";
  version = "1.4.0";

  src = fetchFromGitHub {
    owner = "rejuvenate";
    repo = "lovelace-horizon-card";
    rev = "v${finalAttrs.version}";
    hash = "sha256-z2cJ6BIhNnzUo9nIFxVyrPBVWSKf35fyLXK72pE8TJw=";
  };

  offlineCache = yarn-berry.fetchYarnBerryDeps {
    inherit (finalAttrs) src;
    hash = "sha256-LYPHBnDRcGeXo2btx1A4/e7fr7MYg/2G5GkuG/xDG+I=";
  };

  nativeBuildInputs = [
    nodejs
    yarn-berry
    yarn-berry.yarnBerryConfigHook
  ];

  buildPhase = ''
    runHook preBuild
    yarn run build
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    install -D dist/lovelace-horizon-card.js $out/lovelace-horizon-card.js

    runHook postInstall
  '';

  passthru.entrypoint = "lovelace-horizon-card.js";

  meta = {
    description = "Home Assistant Lovelace card to visualize the position of the Sun and Moon over the horizon";
    homepage = "https://github.com/rejuvenate/lovelace-horizon-card";
    license = lib.licenses.mit;
  };
})
