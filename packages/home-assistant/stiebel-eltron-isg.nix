{
  lib,
  stdenv,
  fetchurl,
  unzip,
}:

stdenv.mkDerivation rec {
  pname = "stiebel-eltron-isg";
  version = "2025.8";

  src = fetchurl {
    url = "https://github.com/pail23/stiebel_eltron_isg_component/releases/download/${version}/stiebel_eltron_isg.zip";
    hash = "sha256-e6dc925252c147d12c00f2036a73cd61c74b20f02da66d29148ff905456cc172";
  };

  nativeBuildInputs = [ unzip ];

  unpackPhase = ''
    unzip $src
  '';

  installPhase = ''
    mkdir -p $out
    cp -r stiebel_eltron_isg $out/
  '';

  passthru.isHomeAssistantComponent = true;

  meta = {
    description = "Stiebel Eltron ISG component for Home Assistant";
    homepage = "https://github.com/pail23/stiebel_eltron_isg_component";
    license = lib.licenses.mit;
  };
}
