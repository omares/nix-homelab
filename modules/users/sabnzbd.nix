{ pkgs, lib, ... }:
{

  users = {
    defaultUserShell = pkgs.zsh;
    mutableUsers = false;
    users = {
      sabnzbd = {
        isNormalUser = true;
        uid = lib.mkDefault 3003;
        group = "starr";
      };
    };
  };
}
