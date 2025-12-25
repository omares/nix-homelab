{
  lib,
  stdenv,
  buildNpmPackage,
  fetchFromGitHub,
  nodejs_22,
  jq,
  moreutils,
  writers,
  nix-update-script,
  python312,
  ffmpeg,
  bashInteractive,
  gcc-unwrapped,
  zlib,
  libdrm,
  libva,
}:
let
  nodejs = nodejs_22;
  python = python312.withPackages (
    ps: with ps; [
      pip
      setuptools
      wheel
      debugpy
    ]
  );
in
(buildNpmPackage.override { inherit nodejs; }) rec {
  pname = "scrypted";
  version = "0.143.0";

  src = fetchFromGitHub {
    owner = "koush";
    repo = "${pname}";
    rev = "v${version}";
    hash = "sha256-5fFyrphAHSAJYfcw5lg7X7zaLt4SXIHQL/3SEPcStiY=";
  };

  npmDepsHash = "sha256-BDAWNudfRYY/uphvc/SFaKU29ceUIEt7DjJ1t7c5O60=";

  sourceRoot = "${src.name}/server";

  nativeBuildInputs = [
    nodejs
    jq
    moreutils
  ];

  # Replace @scrypted/node-pty with official node-pty.
  # @scrypted/node-pty depends on @scrypted/prebuild-install which tries to download
  # prebuilt binaries during npm fetch - this fails in Nix's sandbox.
  # The official node-pty uses node-addon-api and compiles from source instead.
  postPatch = ''
    # Patch package.json: replace @scrypted/node-pty with node-pty
    ${lib.getExe jq} --sort-keys \
      'del(.dependencies["@scrypted/node-pty"]) | .dependencies["node-pty"] = "1.1.0"' \
      package.json \
      | ${lib.getExe' moreutils "sponge"} package.json

    # Patch package-lock.json: remove @scrypted packages, add node-pty + node-addon-api
    ${lib.getExe jq} --sort-keys '
      del(.packages["node_modules/@scrypted/node-pty"]) |
      del(.packages["node_modules/prebuild-install"]) |
      .packages["node_modules/node-pty"] = {
        "version": "1.1.0",
        "resolved": "https://registry.npmjs.org/node-pty/-/node-pty-1.1.0.tgz",
        "integrity": "sha512-20JqtutY6JPXTUnL0ij1uad7Qe1baT46lyolh2sSENDd4sTzKZ4nmAFkeAARDKwmlLjPx6XKRlwRUxwjOy+lUg==",
        "hasInstallScript": true,
        "license": "MIT",
        "dependencies": { "node-addon-api": "^7.1.0" }
      } |
      .packages["node_modules/node-addon-api"] = {
        "version": "7.1.0",
        "resolved": "https://registry.npmjs.org/node-addon-api/-/node-addon-api-7.1.0.tgz",
        "integrity": "sha512-mNcltoe1R8o7STTegSOHdnJNN7s5EUvhoS7ShnTHDyOSd+8H+UdWODq6qSv67PjC8Zc5JRT8+oLAMCr0SIXw7g==",
        "license": "MIT",
        "engines": { "node": "^16 || ^18 || >= 20" }
      }
    ' package-lock.json \
      | ${lib.getExe' moreutils "sponge"} package-lock.json
  '';



  env = {
    SCRYPTED_PYTHON_PATH = lib.getExe python;
    SCRYPTED_PYTHON312_PATH = lib.getExe python;
    SCRYPTED_FFMPEG_PATH = lib.getExe ffmpeg;
    SHELL = lib.getExe bashInteractive;
  };

  makeWrapperArgs =
    let
      # Runtime libraries required by scrypted and its plugins:
      #
      # gcc-unwrapped.lib (libstdc++)
      #   Required by pip-installed Python packages like numpy and openvino.
      #   These packages are compiled against libstdc++ and need it at runtime.
      #
      # zlib
      #   Compression library required by numpy and other Python packages.
      #
      # libdrm (Linux only)
      #   Direct Rendering Manager library for GPU access.
      #   Required by @scrypted/nvr's libav addon for hardware-accelerated video decoding.
      #
      # libva (Linux only)
      #   Video Acceleration API library for hardware video encode/decode.
      #   Required by @scrypted/nvr's libav addon for VA-API hardware acceleration.
      runtimeLibs =
        [ gcc-unwrapped.lib zlib ]
        ++ lib.optionals stdenv.hostPlatform.isLinux [
          libdrm
          libva
        ];
    in
    [
      "--set NODE_ENV production"
      "--set SCRYPTED_PYTHON_PATH ${lib.getExe python}"
      "--set SCRYPTED_PYTHON312_PATH ${lib.getExe python}"
      "--set SCRYPTED_FFMPEG_PATH ${lib.getExe ffmpeg}"
      "--set SHELL ${lib.getExe bashInteractive}"
      "--prefix PATH : ${lib.makeBinPath [ ffmpeg python ]}"
      "--prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath runtimeLibs}"
      # Intel OpenCL/OpenGL libraries for GPU acceleration.
      # This path is populated by hardware.graphics.extraPackages (e.g., intel-compute-runtime).
      "--prefix LD_LIBRARY_PATH : /run/opengl-driver/lib"
    ];

  postInstall = ''
    cp ${writers.writeJSON "install.json" { inherit version; }} $out/install.json
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = ''
      Scrypted is a high performance home video integration platform and NVR with smart detections.
    '';
    mainProgram = "scrypted-serve";
    homepage = "https://github.com/koush/scrypted";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
