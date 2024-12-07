{ lib, ... }:
{
  proxmox = {
    qemuConf = {
      cores = 4;
      memory = 16384;
      diskSize = 51200;
    };
  };

  boot = {
    # Enable ARM64 emulation
    binfmt.emulatedSystems = [ "aarch64-linux" ];
  };
}
