# The recommended values for aarch64 (ARM) are taken from https://github.com/jiangcuo/Proxmox-Port/wiki/Qemu-VM

# After importing add an EFI disk to the proxmox VM with pre enrolled key disabled.

# In case pre enrolled keys are enabled, disabling secure boot is required:
# Enter the BIOS and navigate to "Device Manager" -> "Secure Boot Configuration," then uncheck "Attempt Secure Boot."

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

  virtualisation.diskSize = lib.mkDefault 10240;

  proxmox-custom = {
    qemuConf = {
      bios = "ovmf";
      cores = lib.mkDefault 2;
      memory = lib.mkDefault 2048;
      boot = "order=scsi0";
      net0 = "virtio=00:00:00:00:00:00,bridge=vmbr0,firewall=0";
      scsihw = lib.mkIf isAarch64 "virtio-scsi-pci";
    };

    qemuExtraConf = lib.mkMerge [
      {
        tags = "nixos";
        cpu = homelabLib.mkIfElse isAarch64 "host" "x86-64-v2-AES";
        machine = homelabLib.mkIfElse isAarch64 "i440fx" "q35";
        # Ensure that DHCP is active in the cloud-init configuration
        ipconfig0 = "ip=dhcp,ip6=dhcp";
      }
      (lib.mkIf isAarch64 {
        arch = "aarch64";
        machine = "virt";
      })
    ];

    cloudInit = {
      enable = lib.mkDefault true;
      device = lib.mkIf isAarch64 "sata2";
    };
  };
}
