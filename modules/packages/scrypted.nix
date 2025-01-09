{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  nodejs_20,
  python3,
  ffmpeg,
  gst_all_1,
  cairo,
  gobject-introspection,
  pkg-config,
  node-gyp,
  cacert,
  ...
}:

buildNpmPackage rec {
  pname = "scrypted";
  version = "0.126.0";

  src = fetchFromGitHub {
    owner = "koush";
    repo = "scrypted";
    rev = "v${version}";
    sha256 = "sha256-T4LeNn9+dl+TyWyCpaIPZpMwH71TEh1JcREP2qPbY3E=";
  };

  npmDepsHash = "sha256-EX46ViI21KODYeuL8bR9aiT1/Z7rvmGZJN9RWZF0dVs=";

  sourceRoot = "${src.name}/server";

  makeCacheWritable = true;

  nativeBuildInputs = [
    pkg-config
    nodejs_20
    python3
    gobject-introspection
    cacert
    node-gyp
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
    lib.description = ''
      Scrypted is a high performance home video integration platform and NVR with smart detections.
    '';
    lib.homepage = "https://github.com/koush/scrypted";
    lib.license = lib.licenses.mixed [
      lib.licenses.mit
      lib.licenses.gpl3
    ];
    lib.platforms = lib.platforms.linux ++ lib.platforms.darwin;
    lib.maintainers = lib.maintainers [ ];
  };
}
