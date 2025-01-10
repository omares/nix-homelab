{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  nodejs,
  python3,
  ffmpeg,
  gst_all_1,
  cairo,
  gobject-introspection,
  pkg-config,
  node-gyp,
  callPackage,
  ...
}:
let
  npmHooks = callPackage ./hooks.nix { };
in
buildNpmPackage rec {
  pname = "scrypted";
  version = "0.126.0";

  src = fetchFromGitHub {
    owner = "koush";
    repo = "${pname}";
    rev = "v${version}";
    hash = "sha256-T4LeNn9+dl+TyWyCpaIPZpMwH71TEh1JcREP2qPbY3E=";
  };

  npmDepsHash = "sha256-EX46ViI21KODYeuL8bR9aiT1/Z7rvmGZJN9RWZF0dVs=";

  npmConfigHook = npmHooks.customConfigHook;

  sourceRoot = "${src.name}/server";

  nativeBuildInputs = [
    pkg-config
    nodejs
    python3
    gobject-introspection
  ];

  buildInputs = [
    ffmpeg
    cairo

    python3.pkgs.pip
    python3.pkgs.setuptools
    python3.pkgs.wheel
    python3.pkgs.debugpy
    python3.pkgs.gst-python

    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-libav
    gst_all_1.gst-vaapi
  ];

  postInstall = ''
    cp ${
      lib.escapeShellArg (builtins.toFile "install.json" (builtins.toJSON { inherit version; }))
    } $out/install.json
  '';

  meta = {
    description = ''
      Scrypted is a high performance home video integration platform and NVR with smart detections.
    '';
    mainProgram = "scrypted-serve";
    homepage = "https://github.com/koush/scrypted";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    # maintainers = lib.maintainers [ ];
  };
}
