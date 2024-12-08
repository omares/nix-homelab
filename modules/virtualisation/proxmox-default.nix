# The recommended values for aarch64 (ARM) are taken from https://github.com/jiangcuo/Proxmox-Port/wiki/Qemu-VM
# After importing and starting the VM, secure boot has to be disabled.
# Enter the BIOS and navigate to "Device Manager" -> "Secure Boot Configuration," then uncheck "Attempt Secure Boot."

{ lib, pkgs, ... }:
let
  isAarch64 = pkgs.hostPlatform.isAarch64;
in
{
  proxmox = {
    qemuConf = {
      bios = "ovmf";
      cores = lib.mkDefault 2;
      memory = lib.mkDefault 2048;
      boot = "order=virtio0;net0";
      net0 = "virtio=00:00:00:00:00:00,bridge=vmbr0,firewall=0";
      diskSize = lib.mkDefault 10240;
      scsihw = lib.mkIf isAarch64 "virtio-scsi-pci";
    };

    qemuExtraConf =
      {
        tags = "nixos";
        efidisk0 =
          if isAarch64 then
            "local:1,format=qcow2,pre-enrolled-keys=0"
          else
            "pond:1,format=qcow2,pre-enrolled-keys=0";
        cpu = if isAarch64 then "host" else "x86-64-v2-AES";
      }
      // lib.mkIf isAarch64 {
        arch = "aarch64";
        machine = "virt";
      };

    cloudInit = {
      enable = lib.mkDefault true;
      device = lib.mkIf isAarch64 "sata2";
    };
  };
}
