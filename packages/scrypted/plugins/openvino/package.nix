{
  lib,
  stdenv,
  fetchurl,
  linkFarm,
  writeText,
  python312,
  autoPatchelfHook,
  level-zero,
  ocl-icd,
  unzip,
  zlib,
  mkScryptedPlugin,
  # CLIP smart search models, about 300 MB
  withClip ? true,
}:
let
  versions = import ./versions.nix;

  # From Scrypted server/src/plugin/runtime/python-worker.ts
  scryptedPythonVersion = "20240317";
  pythonMajorMinor = "3.12";

  # nixpkgs' numpy is too new for openvino, and overriding it in the package set rebuilds
  # everything depending on it from source. Use the PyPI wheels pip would install instead.
  mkWheel =
    pname: buildInputs:
    python312.pkgs.buildPythonPackage {
      inherit pname buildInputs;
      inherit (versions.wheels.${pname}) version;
      format = "wheel";
      src = fetchurl { inherit (versions.wheels.${pname}) url hash; };
      nativeBuildInputs = [ autoPatchelfHook ];
      # Dependencies are listed flat in pythonEnv, like pip installs them
      dontCheckRuntimeDeps = true;
    };

  nativeLibs = [
    stdenv.cc.cc.lib
    zlib
  ];

  pythonEnv = python312.withPackages (
    ps:
    [
      (mkWheel "numpy" nativeLibs)
      (mkWheel "openvino" (
        nativeLibs
        ++ [
          level-zero
          ocl-icd
        ]
      ))
      (mkWheel "openvino-telemetry" [ ])
      (mkWheel "opencv-python-headless" nativeLibs)
      (mkWheel "transformers" [ ])
      (mkWheel "huggingface-hub" [ ])
      (mkWheel "tokenizers" nativeLibs)
      (mkWheel "safetensors" nativeLibs)
      (mkWheel "hf-xet" nativeLibs)
    ]
    ++ (with ps; [
      click
      filelock
      fsspec
      httpx
      packaging
      pillow
      pyyaml
      regex
      tqdm
      typer
      typing-extensions
      ptpython
      wheel
    ])
  );

  modelFiles = lib.filterAttrs (model: _: withClip || model != "clip") versions.models.files;

  # Layout written by snapshot_download(local_dir=files/hf/openvino/<model>): openvino/<model>/<file>
  models = linkFarm "scrypted-openvino-models" (
    lib.concatLists (
      lib.mapAttrsToList (
        model: files:
        lib.mapAttrsToList (file: hash: {
          name = "${model}/openvino/${model}/${file}";
          path = fetchurl {
            name = "${model}-${file}";
            url = "https://huggingface.co/scrypted/plugin-models/resolve/${versions.models.commit}/openvino/${model}/${file}";
            inherit hash;
          };
        }) files
      ) modelFiles
    )
  );

  # HF hub cache layout read by CLIPProcessor.from_pretrained
  clipProcessorCache =
    let
      inherit (versions.clipProcessor) repo commit files;
      repoDir = "models--${builtins.replaceStrings [ "/" ] [ "--" ] repo}";
    in
    linkFarm "scrypted-openvino-clip-processor" (
      [
        {
          name = "${repoDir}/refs/main";
          path = writeText "main" commit;
        }
      ]
      ++ lib.mapAttrsToList (file: hash: {
        name = "${repoDir}/snapshots/${commit}/${file}";
        path = fetchurl {
          name = "clip-processor-${file}";
          url = "https://huggingface.co/${repo}/resolve/${commit}/${file}";
          inherit hash;
        };
      }) files
    );

in
mkScryptedPlugin {
  pname = "openvino";
  version = versions.version;
  hash = versions.hash;

  nativeBuildInputs = [ unzip ];

  postInstall = ''
    mkdir -p $out/python-env

    # Symlink Python site-packages
    for pkg in ${pythonEnv}/${pythonEnv.sitePackages}/*; do
      ln -s "$pkg" $out/python-env/
    done

    # Load everything the way the plugin does when it is offline
    HOME=$TMPDIR HF_HUB_OFFLINE=1 HF_HUB_CACHE=${clipProcessorCache} \
      ${pythonEnv.interpreter} - ${lib.escapeShellArgs (lib.attrNames modelFiles)} <<'EOF'
    import os, sys
    import numpy, cv2, PIL
    import openvino as ov
    from huggingface_hub import snapshot_download
    from transformers import CLIPProcessor

    assert numpy.__version__ == "${versions.wheels.numpy.version}", numpy.__version__

    core = ov.Core()
    for model in sys.argv[1:]:
        path = snapshot_download(
            repo_id="scrypted/plugin-models",
            allow_patterns=f"openvino/{model}/*",
            local_files_only=True,
            local_dir=os.path.join("${models}", model),
        )
        path = os.path.join(path, "openvino", model)
        for xml in [f for f in os.listdir(path) if f.endswith(".xml")]:
            core.read_model(os.path.join(path, xml))

    if "clip" in sys.argv[1:]:
        CLIPProcessor.from_pretrained("${versions.clipProcessor.repo}", local_files_only=True)
    EOF

    # Extract requirements.txt from plugin.zip for marker files
    ${unzip}/bin/unzip -p $out/plugin.zip requirements.txt > $out/python-env/requirements.txt
    cp $out/python-env/requirements.txt $out/python-env/requirements.installed.txt

    printf 'ptpython\nwheel' > $out/python-env/requirements.scrypted.txt
    cp $out/python-env/requirements.scrypted.txt $out/python-env/requirements.scrypted.installed.txt
  '';

  passthru = finalAttrs: {
    inherit
      pythonMajorMinor
      scryptedPythonVersion
      pythonEnv
      models
      clipProcessorCache
      ;
    updateScript = ./update.sh;

    provision = {
      symlinks = [
        {
          target = "python${pythonMajorMinor}-Linux-x86_64-${scryptedPythonVersion}";
          path = "${finalAttrs.finalPackage}/python-env";
        }
      ]
      ++ map (model: {
        target = "files/hf/openvino/${model}";
        path = "${models}/${model}";
      }) (lib.attrNames modelFiles);

      environment = {
        HF_HUB_OFFLINE = "1";
      }
      // lib.optionalAttrs withClip {
        HF_HUB_CACHE = "${clipProcessorCache}";
      };
    };
  };

  meta = {
    description = "Scrypted OpenVINO plugin with pre-provisioned Python environment and models";
    homepage = "https://github.com/koush/scrypted";
    license = lib.licenses.mit;
    platforms = [ "x86_64-linux" ];
  };
}
