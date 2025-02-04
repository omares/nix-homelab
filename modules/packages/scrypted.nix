{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  nodejs_20,
  callPackage,
  nix-update-script,
}:
let
  npmHooks = callPackage ./hooks.nix { };
  nodejs = nodejs_20;
in
(buildNpmPackage.override { inherit nodejs; }) rec {
  pname = "scrypted";
  version = "0.131.0";

  src = fetchFromGitHub {
    owner = "koush";
    repo = "${pname}";
    rev = "v${version}";
    hash = "sha256-BXBrGY4Adsc6DaPPi1J9rzGt+a/3v7+z2eRrXgMzSMg=";
  };

  npmDepsHash = "sha256-7JyXgSVnmS8OhUpUptn2dspOFMxs3LRNxzDzJS3MXpg=";

  # A custom npm hook is required to skip the npm rebuild phase
  npmConfigHook = npmHooks.customConfigHook;

  sourceRoot = "${src.name}/server";

  nativeBuildInputs = [ nodejs ];

  makeWrapperArgs = [ "--set NODE_ENV production" ];

  postInstall = ''
    cp ${
      lib.escapeShellArg (builtins.toFile "install.json" (builtins.toJSON { inherit version; }))
    } $out/install.json
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
    # maintainers = lib.maintainers [ ];
  };
}
