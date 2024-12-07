{ pkgs, lib, ... }:
{

  users = {
    users = {
      root = {
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKM/Wfv6llweYoV2hLedBp9p6KRUkY7aPMF0zc6Uw8Fi"
        ];
      };
    };
  };
}
