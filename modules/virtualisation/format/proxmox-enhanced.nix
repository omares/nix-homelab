/*
  Based on the [nixpkgs Proxmox image](https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/virtualisation/proxmox-image.nix#L1):

  1. Added the option `diskType`, which allows specification of the bus/device for the main disk, enabling the creation of SCSI disks.
  2. Renamed the `virtio0` setting to `mainDisk`, making the option name more generic, as the disk type now controls the type.
     Use "local-lvm:vm-9999-disk-0,discard=on,ssd=1,iothread=1" and "scsi" diskTye when using a NVMe M.2 disk.
  3. EFI disk is automatically created when using OVMF/EFI partition types.
  4. Additional kernel modules can be added via `extraModules` and `extraInitrdModules`.
  5. Enabled the boot loader screen to display for 1 second.

  Unfortunately, I did not achieve creating an EFI disk without pre-enrolled keys.
  To resolve issues when starting the imported VM, the existing EFI disk must be removed,
  and a new one has to be created through the Proxmox interface without pre-enrolled keys.
*/

{
  inputs,
  config,
  pkgs,
  lib,
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

  options.mares.proxmox-enhanced = {
    diskType = lib.mkOption {
      type = lib.types.enum [
        "virtio"
        "scsi"
        "ide"
        "sata"
      ];
      default = "virtio";
      description = ''
        Type of disk to use. When using SCSI, optimized settings (discard=on, ssd=1, iothread=1) are applied.
      '';
    };

    kernelModules = {
      extraModules = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = ''
          Additional kernel modules to include in the image
        '';
      };

      extraInitrdModules = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = ''
          Additional initrd modules to include in the image
        '';
      };
    };

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

      mainDisk = lib.mkOption {
        type = lib.types.str;
        default = "local-lvm:vm-9999-disk-0";
        description = ''
          Configuration for the main disk. When using SCSI disk type, optimized settings are applied.
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
        Defaults to 'legacy' for 'proxmox-enhanced.qemuConf.bios="seabios"' (default), other bios values defaults to 'efi'.
        Use 'hybrid' to build grub-based hybrid bios+efi images.
      '';
      default = if config.mares.proxmox-enhanced.qemuConf.bios == "seabios" then "legacy" else "efi";
      defaultText = lib.literalExpression ''if config.mares.proxmox-enhanced.qemuConf.bios == "seabios" then "legacy" else "efi"'';
      example = "hybrid";
    };

    filenameSuffix = lib.mkOption {
      type = lib.types.str;
      default = config.mares.proxmox-enhanced.qemuConf.name;
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
      cfg = config.mares.proxmox-enhanced;

      diskDevice = "${cfg.diskType}0";
      diskStorage = builtins.head (builtins.split ":" cfg.qemuConf.mainDisk);

      cfgLine = name: value: ''
        ${name}: ${builtins.toString value}
      '';

      inherit (cfg) partitionTableType;
      supportEfi = partitionTableType == "efi" || partitionTableType == "hybrid";
      supportBios =
        partitionTableType == "legacy"
        || partitionTableType == "hybrid"
        || partitionTableType == "legacy+gpt";
      hasBootPartition = partitionTableType == "efi" || partitionTableType == "hybrid";
      hasNoFsPartition = partitionTableType == "hybrid" || partitionTableType == "legacy+gpt";

      cfgFile =
        fileName: properties:
        pkgs.writeTextDir fileName ''
          # generated by NixOS
          ${lib.concatStrings (lib.mapAttrsToList cfgLine properties)}
          #qmdump#map:${diskDevice}:drive-${diskDevice}:${diskStorage}:raw:
          ${lib.optionalString supportEfi "#qmdump#map:efidisk0:drive-efidisk0:${builtins.head (builtins.split ":" "local-lvm:vm-9999-efidisk-0")}:raw:"}
        '';

    in
    {
      assertions = [
        {
          assertion =
            config.boot.loader.systemd-boot.enable -> config.mares.proxmox-enhanced.qemuConf.bios == "ovmf";
          message = "systemd-boot requires 'ovmf' bios";
        }
        {
          assertion = partitionTableType == "efi" -> config.mares.proxmox-enhanced.qemuConf.bios == "ovmf";
          message = "'efi' disk partitioning requires 'ovmf' bios";
        }
        {
          assertion =
            partitionTableType == "legacy" -> config.mares.proxmox-enhanced.qemuConf.bios == "seabios";
          message = "'legacy' disk partitioning requires 'seabios' bios";
        }
        {
          assertion =
            partitionTableType == "legacy+gpt" -> config.mares.proxmox-enhanced.qemuConf.bios == "seabios";
          message = "'legacy+gpt' disk partitioning requires 'seabios' bios";
        }
      ];

      image.baseName = lib.mkDefault "vzdump-qemu-${cfg.filenameSuffix}";
      image.extension = "vma.zst";
      system.build.image = config.system.build.VMA;

      system.build.VMA = import "${toString inputs.nixpkgs}/nixos/lib/make-disk-image.nix" {
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
            ${lib.optionalString supportEfi ''
              ${pkgs.qemu}/bin/qemu-img create -f raw $out/efidisk.raw 4M
            ''}

            ${vma}/bin/vma create "${config.image.baseName}.vma" \
              -c ${
                cfgFile "qemu-server.conf" (
                  removeAttrs cfg.qemuConf [
                    "additionalSpace"
                    "bootSize"
                    "mainDisk"
                  ]
                  // {
                    "${cfg.diskType}0" = cfg.qemuConf.mainDisk;
                  }
                  // lib.optionalAttrs supportEfi {
                    "efidisk0" = "local-lvm:vm-9999-efidisk-0,efitype=4m,pre-enrolled-keys=0,size=4M";
                  }
                  // cfg.qemuExtraConf
                )
              }/qemu-server.conf \
              drive-${diskDevice}=$diskImage \
              ${lib.optionalString supportEfi "drive-efidisk0=$out/efidisk.raw"}

            rm $diskImage
            ${lib.optionalString supportEfi ''
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
        kernelParams = [ "console=ttyS0" ];
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

        loader.timeout = 1;
        initrd.availableKernelModules = [
          "uas"
          "virtio_blk"
          "virtio_pci"
        ] ++ cfg.kernelModules.extraModules;

        initrd.kernelModules = cfg.kernelModules.extraInitrdModules;
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

      mares.proxmox-enhanced.qemuExtraConf.${cfg.cloudInit.device} =
        "${cfg.cloudInit.defaultStorage}:vm-9999-cloudinit,media=cdrom";
    };
}
