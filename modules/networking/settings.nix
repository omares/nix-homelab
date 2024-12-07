{ lib, ... }:
{

  networking = {
    hostName = lib.mkDefault "vm-23-11-NixOS";
    useNetworkd = true;
  };
}
