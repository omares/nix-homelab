/*
  Based on the nixpkgs Proxmox image (nixpkgs/nixos/modules/virtualisation/proxmox-image.nix):

  Changes:

  1. Storage Configuration:
     - Changed from VirtIO disk to SCSI
     - Added SCSI-specific options: discard=on, iothread=1, ssd=1

  2. EFI/OVMF Configuration:
     - Pre-creates EFI disk for OVMF support
     - Note: After importing template, EFI disk needs to be manually recreated due to secure boot limitations

  3. Kernel Module Configuration:
     - Added modules for SCSI, USB, and basic VirtIO functionality

  Manual Steps to Apply After Import:
  1. Remove existing EFI disk
  2. Re-add EFI disk with "pre-enrolled keys" unchecked
*/
{
  config,
  pkgs,
  lib,
  nixpkgs,
  modulesPath,
  ...
}:

{
  imports = [
    "${modulesPath}/virtualisation/disk-size-option.nix"
    "${modulesPath}/image/file-options.nix"
    (lib.mkRenamedOptionModuleWith {
      sinceRelease = 2411;
      from = [
        "proxmox"
        "qemuConf"
        "diskSize"
      ];
      to = [
        "virtualisation"
        "diskSize"
      ];
    })
  ];

  options.proxmox-custom = {
    qemuConf = {
      # essential configs
      boot = lib.mkOption {
        type = lib.types.str;
        default = "";
        example = "order=scsi0;net0";
        description = ''
          Default boot device. PVE will try all devices in its default order if this value is empty.
        '';
      };
      scsihw = lib.mkOption {
        type = lib.types.str;
        default = "virtio-scsi-single";
        example = "lsi";
        description = ''
          SCSI controller type. Must be one of the supported values given in
          <https://pve.proxmox.com/wiki/Qemu/KVM_Virtual_Machines>
        '';
      };
      scsi0 = lib.mkOption {
        type = lib.types.str;
        default = "local-lvm:vm-9999-disk-0,discard=on,ssd=1,iothread=1";
        example = "ceph:vm-123-disk-0";
        description = ''
          Configuration for the default SCSI disk. It can be used as a cue for PVE to autodetect the target storage.
          This parameter is required by PVE even if it isn't used.
        '';
      };
      efidisk0 = lib.mkOption {
        type = lib.types.str;
        default = "local-lvm:vm-9999-efidisk-0,efitype=4m,size=4M,pre-enrolled-keys=0";
        description = ''
          EFI disk configuration. pre-enrolled-keys=0 disables secure boot keys.
        '';
      };
      ostype = lib.mkOption {
        type = lib.types.str;
        default = "l26";
        description = ''
          Guest OS type
        '';
      };
      cores = lib.mkOption {
        type = lib.types.ints.positive;
        default = 1;
        description = ''
          Guest core count
        '';
      };
      memory = lib.mkOption {
        type = lib.types.ints.positive;
        default = 1024;
        description = ''
          Guest memory in MB
        '';
      };
      bios = lib.mkOption {
        type = lib.types.enum [
          "seabios"
          "ovmf"
        ];
        default = "seabios";
        description = ''
          Select BIOS implementation (seabios = Legacy BIOS, ovmf = UEFI).
        '';
      };
      # optional configs
      name = lib.mkOption {
        type = lib.types.str;
        default = "nixos-${config.system.nixos.label}";
        description = ''
          VM name
        '';
      };
      additionalSpace = lib.mkOption {
        type = lib.types.str;
        default = "512M";
        example = "2048M";
        description = ''
          additional disk space to be added to the image if diskSize "auto"
          is used.
        '';
      };
      bootSize = lib.mkOption {
        type = lib.types.str;
        default = "256M";
        example = "512M";
        description = ''
          Size of the boot partition. Is only used if partitionTableType is
          either "efi" or "hybrid".
        '';
      };
      net0 = lib.mkOption {
        type = lib.types.commas;
        default = "virtio=00:00:00:00:00:00,bridge=vmbr0,firewall=1";
        description = ''
          Configuration for the default interface. When restoring from VMA, check the
          "unique" box to ensure device mac is randomized.
        '';
      };
      serial0 = lib.mkOption {
        type = lib.types.str;
        default = "socket";
        example = "/dev/ttyS0";
        description = ''
          Create a serial device inside the VM (n is 0 to 3), and pass through a host serial device (i.e. /dev/ttyS0),
          or create a unix socket on the host side (use qm terminal to open a terminal connection).
        '';
      };
      agent = lib.mkOption {
        type = lib.types.bool;
        apply = x: if x then "1" else "0";
        default = true;
        description = ''
          Expect guest to have qemu agent running
        '';
      };
    };
    qemuExtraConf = lib.mkOption {
      type =
        with lib.types;
        attrsOf (oneOf [
          str
          int
        ]);
      default = { };
      example = lib.literalExpression ''
        {
          cpu = "host";
          onboot = 1;
        }
      '';
      description = ''
        Additional options appended to qemu-server.conf
      '';
    };
    partitionTableType = lib.mkOption {
      type = lib.types.enum [
        "efi"
        "hybrid"
        "legacy"
        "legacy+gpt"
      ];
      description = ''
        Partition table type to use. See make-disk-image.nix partitionTableType for details.
        Defaults to 'legacy' for 'proxmox.qemuConf.bios="seabios"' (default), other bios values defaults to 'efi'.
        Use 'hybrid' to build grub-based hybrid bios+efi images.
      '';
      default = if config.proxmox-custom.qemuConf.bios == "seabios" then "legacy" else "efi";
      defaultText = lib.literalExpression ''if config.proxmox-custom.qemuConf.bios == "seabios" then "legacy" else "efi"'';
      example = "hybrid";
    };
    filenameSuffix = lib.mkOption {
      type = lib.types.str;
      default = config.proxmox-custom.qemuConf.name;
      example = "999-nixos_template";
      description = ''
        Filename of the image will be vzdump-qemu-''${filenameSuffix}.vma.zstd.
        This will also determine the default name of the VM on restoring the VMA.
        Start this value with a number if you want the VMA to be detected as a backup of
        any specific VMID.
      '';
    };
    cloudInit = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Whether the VM should accept cloud init configurations from PVE.
        '';
      };
      defaultStorage = lib.mkOption {
        default = "local-lvm";
        example = "tank";
        type = lib.types.str;
        description = ''
          Default storage name for cloud init drive.
        '';
      };
      device = lib.mkOption {
        default = "ide2";
        example = "scsi0";
        type = lib.types.str;
        description = ''
          Bus/device to which the cloud init drive is attached.
        '';
      };
    };
  };

  config =
    let
      cfg = config.proxmox-custom;
      cfgLine = name: value: ''
        ${name}: ${builtins.toString value}
      '';
      scsi0Storage = builtins.head (builtins.split ":" cfg.qemuConf.scsi0);
      cfgFile =
        fileName: properties:
        pkgs.writeTextDir fileName ''
          # generated by NixOS
          ${lib.concatStrings (lib.mapAttrsToList cfgLine properties)}
          #qmdump#map:scsi0:drive-scsi0:${scsi0Storage}:raw:
          ${lib.optionalString (cfg.qemuConf.bios == "ovmf")
            "#qmdump#map:efidisk0:drive-efidisk0:${builtins.head (builtins.split ":" cfg.qemuConf.efidisk0)}:raw:"
          }
        '';
      inherit (cfg) partitionTableType;
      supportEfi = partitionTableType == "efi" || partitionTableType == "hybrid";
      supportBios =
        partitionTableType == "legacy"
        || partitionTableType == "hybrid"
        || partitionTableType == "legacy+gpt";
      hasBootPartition = partitionTableType == "efi" || partitionTableType == "hybrid";
      hasNoFsPartition = partitionTableType == "hybrid" || partitionTableType == "legacy+gpt";
    in
    {
      assertions = [
        {
          assertion = config.boot.loader.systemd-boot.enable -> config.proxmox-custom.qemuConf.bios == "ovmf";
          message = "systemd-boot requires 'ovmf' bios";
        }
        {
          assertion = partitionTableType == "efi" -> config.proxmox-custom.qemuConf.bios == "ovmf";
          message = "'efi' disk partitioning requires 'ovmf' bios";
        }
        {
          assertion = partitionTableType == "legacy" -> config.proxmox-custom.qemuConf.bios == "seabios";
          message = "'legacy' disk partitioning requires 'seabios' bios";
        }
        {
          assertion = partitionTableType == "legacy+gpt" -> config.proxmox-custom.qemuConf.bios == "seabios";
          message = "'legacy+gpt' disk partitioning requires 'seabios' bios";
        }
      ];
      image.baseName = lib.mkDefault "vzdump-qemu-${cfg.filenameSuffix}";
      image.extension = "vma.zst";
      system.build.image = config.system.build.VMA;

      system.build.VMA = import "${nixpkgs}/nixos/lib/make-disk-image.nix" {
        name = "proxmox-${cfg.filenameSuffix}";
        baseName = config.image.baseName;
        inherit (cfg) partitionTableType;
        postVM =
          let
            # Build qemu with PVE's patch that adds support for the VMA format
            vma =
              (pkgs.qemu_kvm.override {
                alsaSupport = false;
                pulseSupport = false;
                sdlSupport = false;
                jackSupport = false;
                gtkSupport = false;
                vncSupport = false;
                smartcardSupport = false;
                spiceSupport = false;
                ncursesSupport = false;
                libiscsiSupport = false;
                tpmSupport = false;
                numaSupport = false;
                seccompSupport = false;
                guestAgentSupport = false;
              }).overrideAttrs
                (super: rec {
                  # Check https://github.com/proxmox/pve-qemu/tree/master for the version
                  # of qemu and patch to use
                  version = "9.0.0";
                  src = pkgs.fetchurl {
                    url = "https://download.qemu.org/qemu-${version}.tar.xz";
                    hash = "sha256-MnCKxmww2MiSYz6paMdxwcdtWX1w3erSGg0izPOG2mk=";
                  };
                  patches = [
                    # Proxmox' VMA tool is published as a particular patch upon QEMU
                    "${
                      pkgs.fetchFromGitHub {
                        owner = "proxmox";
                        repo = "pve-qemu";
                        rev = "14afbdd55f04d250bd679ca1ad55d3f47cd9d4c8";
                        hash = "sha256-lSJQA5SHIHfxJvMLIID2drv2H43crTPMNIlIT37w9Nc=";
                      }
                    }/debian/patches/pve/0027-PVE-Backup-add-vma-backup-format-code.patch"
                  ];

                  buildInputs = super.buildInputs ++ [ pkgs.libuuid ];
                  nativeBuildInputs = super.nativeBuildInputs ++ [ pkgs.perl ];

                });
          in
          ''
            # Create empty EFI disk if using OVMF
            ${lib.optionalString (cfg.qemuConf.bios == "ovmf") ''
              # Create empty EFI disk
              ${pkgs.qemu}/bin/qemu-img create -f raw $out/efidisk.raw 4M
            ''}

            ${vma}/bin/vma create "${config.image.baseName}.vma" \
              -c ${
                cfgFile "qemu-server.conf" (cfg.qemuConf // cfg.qemuExtraConf)
              }/qemu-server.conf drive-scsi0=$diskImage \
              ${lib.optionalString (cfg.qemuConf.bios == "ovmf") "drive-efidisk0=$out/efidisk.raw"}

            rm $diskImage
            ${lib.optionalString (cfg.qemuConf.bios == "ovmf") ''
              rm $out/efidisk.raw
            ''}

            ${pkgs.zstd}/bin/zstd "${config.image.baseName}.vma"
            mv "${config.image.fileName}" $out/

            mkdir -p $out/nix-support
            echo "file vma $out/${config.image.fileName}" > $out/nix-support/hydra-build-products
          '';
        inherit (cfg.qemuConf) additionalSpace bootSize;
        inherit (config.virtualisation) diskSize;
        format = "raw";
        inherit config lib pkgs;
      };

      boot = {
        growPartition = true;
        kernelParams = [ "console=tty0" ];
        loader.grub = {
          device = lib.mkDefault (
            if (hasNoFsPartition || supportBios) then
              # Even if there is a separate no-fs partition ("/dev/disk/by-partlabel/no-fs" i.e. "/dev/vda2"),
              # which will be used the bootloader, do not set it as loader.grub.device.
              # GRUB installation fails, unless the whole disk is selected.
              "/dev/vda"
            else
              "nodev"
          );
          efiSupport = lib.mkDefault supportEfi;
          efiInstallAsRemovable = lib.mkDefault supportEfi;
        };

        loader.timeout = 3;
        initrd = {
          availableKernelModules = [
            "virtio_pci"
            "virtio_blk"
            "virtio_net"

            "virtio_scsi" # VirtIO SCSI support
            "scsi_mod" # Core SCSI support
            "sd_mod" # SCSI disk support

            "ata_piix" # IDE/SATA support
            "ahci" # SATA support

            "uas" # USB Attached SCSI
            "usb_storage" # USB storage support
            "usbcore" # Core USB support
            "ehci_pci" # USB 2.0 support
            "xhci_pci" # USB 3.0 support

            "ext4"
          ];
          kernelModules = [
            "virtio_scsi"
            "virtio_balloon"
            "virtio_console"
            "virtio_rng"
            "scsi_mod"
            "sd_mod"
          ];
        };
      };

      fileSystems."/" = {
        device = "/dev/disk/by-label/nixos";
        autoResize = true;
        fsType = "ext4";
      };
      fileSystems."/boot" = lib.mkIf hasBootPartition {
        device = "/dev/disk/by-label/ESP";
        fsType = "vfat";
      };

      networking = lib.mkIf cfg.cloudInit.enable {
        hostName = lib.mkForce "";
        useDHCP = false;
      };

      services = {
        cloud-init = lib.mkIf cfg.cloudInit.enable {
          enable = true;
          network.enable = true;
        };
        sshd.enable = lib.mkDefault true;
        qemuGuest.enable = true;
      };

      proxmox-custom.qemuExtraConf.${cfg.cloudInit.device} =
        "${cfg.cloudInit.defaultStorage}:vm-9999-cloudinit,media=cdrom";

      formatAttr = "VMA";
      fileExtension = ".vma.zst";
    };
}
