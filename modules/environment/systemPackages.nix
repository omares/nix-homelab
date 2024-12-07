{ pkgs, lib, ... }:
{

  environment.systemPackages = with pkgs; [
    curl
    wget
  ];

}
