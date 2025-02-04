{
  config,
  lib,
  ...
}:

let
  cfg = config.cluster.vm-profile;
in
{
  # The import is necessary when the VM profile is used in a non-packaging context.
  imports = [ ./format/proxmox-enhanced.nix ];

  options.cluster.vm-profile = {
    template = lib.mkOption {
      type = lib.types.enum [
        "proxmox-legacy"
        "proxmox-optimized"
        "proxmox-builder"
        "proxmox-arm"
      ];
      description = lib.mdDoc ''
        Which Proxmox VM template to use.

        Available options:
        - proxmox-legacy: i440fx-based VM with VirtIO storage (higher compatibility)
        - proxmox-optimized: q35-based VM with optimized SCSI storage (recommended)
        - proxmox-builder: Specialized VM for Nix remote building
        - proxmox-arm: virt based VM optimzed for aarch64 hardware
      '';
      example = "proxmox-optimized";
      default = "proxmox-optimized";
    };
  };

  config =

    let
      isBuilder = cfg.template == "proxmox-builder";
      isOptimized = cfg.template == "proxmox-optimized" || isBuilder;
      isAarch64 = cfg.template == "proxmox-arm";

      diskSize = if isBuilder then 51200 else 10240;
      cores = if isBuilder then 4 else 2;
      memory = if isBuilder then (16 * 1024) else (2 * 1024);

    in
    {

      virtualisation.diskSize = lib.mkDefault diskSize;

      proxmox-enhanced = {
        diskType = if isOptimized then "scsi" else "virtio";

        kernelModules = {
          extraModules =
            [ ]
            ++ lib.optionals isOptimized [
              "virtio_scsi"
              "scsi_mod"
              "sd_mod"
              "ata_piix"
              "ahci"
              "uas"
              "usb_storage"
              "usbcore"
              "ehci_pci"
              "xhci_pci"
              "ext4"
            ];
          extraInitrdModules =
            [ ]
            ++ lib.optionals isOptimized [
              "virtio_scsi"
              "virtio_balloon"
              "virtio_console"
              "virtio_rng"
              "scsi_mod"
              "sd_mod"
            ];
        };

        qemuConf = {
          bios = "ovmf";
          cores = lib.mkDefault cores;
          memory = lib.mkDefault memory;
          boot = "order=scsi0";
          net0 = "virtio=00:00:00:00:00:00,bridge=vmbr0,firewall=0";
          scsihw = lib.mkIf isAarch64 "virtio-scsi-pci";
          mainDisk = lib.mkIf isOptimized "local-lvm:vm-9999-disk-0,discard=on,ssd=1,iothread=1";
        };

        qemuExtraConf = lib.mkMerge [
          {
            tags = "nixos";
            cpu = "x86-64-v2-AES";
            machine = if isOptimized then "q35" else "i440fx";
            # Ensures that DHCP is active in the cloud-init configuration
            ipconfig0 = "ip=dhcp,ip6=dhcp";
          }
          (lib.mkIf isAarch64 {
            arch = "aarch64";
            cpu = lib.mkForce "host";
            machine = lib.mkForce "virt";
          })
        ];

        partitionTableType = lib.mkIf isOptimized "efi";

        cloudInit = {
          device = lib.mkIf isAarch64 "sata2";
        };
      };
    };
}
