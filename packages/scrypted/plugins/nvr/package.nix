{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  libdrm,
  libva,
  libx11,
  libxcb,
  nodejs_22,
  ocl-icd,
  zlib,
  mkScryptedPlugin,
}:
let
  versions = import ./versions.nix;

  # process.versions.modules of Node 22, the runtime of the scrypted package
  nodeAbi = "127";
  libavName = "libav-v${versions.libav.version}-node-v${nodeAbi}-linux-x64";

  # NVR downloads this addon from GitHub at runtime unless it can load it from the plugin volume
  libav = stdenv.mkDerivation {
    pname = "scrypted-libav";
    inherit (versions.libav) version;

    src = fetchurl {
      url = "https://github.com/scryptedapp/libav/releases/download/v${versions.libav.version}/${libavName}.tar.gz";
      inherit (versions.libav) hash;
    };

    sourceRoot = ".";

    nativeBuildInputs = [ autoPatchelfHook ];
    buildInputs = [
      stdenv.cc.cc.lib
      libdrm
      libva
      libx11
      libxcb
      ocl-icd
      zlib
    ];

    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -r build $out/
      runHook postInstall
    '';

    doInstallCheck = true;
    installCheckPhase = ''
      ${lib.getExe nodejs_22} -e 'require(process.argv[1])' $out/build/Release/addon.node
    '';
  };
in
mkScryptedPlugin {
  pname = "nvr";
  inherit (versions) version hash;

  passthru = _finalAttrs: {
    inherit libav;
    updateScript = ./update.sh;

    # Path the plugin installs libav to: $SCRYPTED_PLUGIN_VOLUME/<version>/<release name>
    provision.symlinks = [
      {
        target = "${versions.libav.version}/${libavName}";
        path = "${libav}";
      }
    ];
  };

  meta.description = "Scrypted NVR - NVR plugin for Scrypted, with pre-provisioned libav";
}
