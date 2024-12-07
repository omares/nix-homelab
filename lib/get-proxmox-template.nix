{ splitString }:
system:
let
  arch = builtins.head (splitString "-" system);
  templates = {
    aarch64 = ../modules/virtualisation/proxmox-aarch64.nix;
    x86_64 = ../modules/virtualisation/proxmox-x86_64.nix;
  };
in
templates.${arch} or (throw "Unsupported architecture: ${arch} (from system ${system})")
