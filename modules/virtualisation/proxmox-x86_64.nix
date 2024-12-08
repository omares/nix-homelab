{ lib, ... }:
{
  proxmox = {
    qemuConf = {
      bios = "ovmf";
      cores = lib.mkDefault 2;
      memory = lib.mkDefault 2048;
      boot = "order=virtio0;net0";
      net0 = "virtio=00:00:00:00:00:00,bridge=vmbr0,firewall=0";
      diskSize = lib.mkDefault 10240;
    };

    qemuExtraConf = {
      # for reference: https://pve.proxmox.com/wiki/Qemu/KVM_Virtual_Machines#qm_virtual_machines_settings
      cpu = "x86-64-v2-AES";
      tags = "nixos";
      efidisk0 = "pond:1,format=qcow2,pre-enrolled-keys=0";
    };

    cloudInit = {
      enable = lib.mkDefault true;
    };
  };
}
