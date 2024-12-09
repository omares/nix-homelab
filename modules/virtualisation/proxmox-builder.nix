{
  lib,
  homelabLib,
  pkgs,
  ...
}:
let
  isAarch64 = pkgs.hostPlatform.isAarch64;
in
{
  proxmox = {
    qemuConf = {
      cores = 4;
      memory = homelabLib.mkIfElse isAarch64 (6 * 1024) (16 * 1024);
      diskSize = 51200;
    };
  };
}
