{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
}:

buildNpmPackage rec {
  pname = "layout-card";
  version = "2.4.7";

  src = fetchFromGitHub {
    owner = "thomasloven";
    repo = "lovelace-layout-card";
    rev = "v${version}";
    hash = "sha256-xni9cTgv5rdpr+Oo4Zh/d/2ERMiqDiTFGAiXEnigqjc=";
  };

  npmDepsHash = "sha256-Nmi51kCj/e9A0PmO/DIvOplgBnQzIEmCbuM5HjmdKGw=";

  dontNpmBuild = true;

  installPhase = ''
    runHook preInstall

    install -D layout-card.js $out/layout-card.js

    runHook postInstall
  '';

  passthru.entrypoint = "layout-card.js";

  meta = {
    description = "Layout Card - Advanced grid layouts for Home Assistant Lovelace";
    homepage = "https://github.com/thomasloven/lovelace-layout-card";
    license = lib.licenses.mit;
  };
}
