# Recommended values taken from https://github.com/jiangcuo/Proxmox-Port/wiki/Qemu-VM
# After importing and starting the VM, secure boot has to be disabled.
# Enter the BIOS and navigate to "Device Manager" -> "Secure Boot Configuration," then uncheck "Attempt Secure Boot."

{ lib, ... }:
{
  proxmox = {
    qemuConf = {
      bios = "ovmf";
      cores = 2;
      memory = 2048;
      boot = "order=virtio0;net0";
      net0 = "virtio=00:00:00:00:00:00,bridge=vmbr0,firewall=0";
      scsihw = "virtio-scsi-pci";
      diskSize = lib.mkDefault 10240;
    };

    qemuExtraConf = {
      arch = "aarch64";
      machine = "virt";
      cpu = "host";
      tags = "nixos";
      efidisk0 = "local:1,format=qcow2,pre-enrolled-keys=0";
    };

    cloudInit = {
      enable = true;
      device = "sata2";
    };
  };
}
