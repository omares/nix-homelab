{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
}:

buildNpmPackage rec {
  pname = "card-tools";
  version = "11";

  src = fetchFromGitHub {
    owner = "thomasloven";
    repo = "lovelace-card-tools";
    rev = version;
    hash = "sha256-QpRSD3aFT12/nGykMnRZt9aLCU1fJ3r+8WPE4681LbA=";
  };

  npmDepsHash = "sha256-hTk8d5sSUlaOWfJ/zh1dXj5gu4dlnMh/AgsVVQge2tE=";

  dontNpmBuild = true;

  installPhase = ''
    runHook preInstall

    install -D card-tools.js $out/card-tools.js

    runHook postInstall
  '';

  passthru.entrypoint = "card-tools.js";

  meta = {
    description = "A collection of tools for other lovelace plugins to use";
    homepage = "https://github.com/thomasloven/lovelace-card-tools";
    license = lib.licenses.mit;
  };
}
