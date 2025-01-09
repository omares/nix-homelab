{
  homelabLib,
  pkgs,
  ...
}:
let
  isAarch64 = pkgs.hostPlatform.isAarch64;
in
{
  virtualisation.diskSize = 51200;

  proxmox = {
    qemuConf = {
      cores = 4;
      memory = homelabLib.mkIfElse isAarch64 (6 * 1024) (16 * 1024);
    };
  };
}
