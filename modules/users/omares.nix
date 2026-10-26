{ pkgs, config, ... }:
{

  config = {
    users = {
      defaultUserShell = pkgs.zsh;
      mutableUsers = false;
      users = {
        omares = {
          uid = config.ids.uids.omares;
          extraGroups = [ "wheel" ];
          isNormalUser = true;
          openssh.authorizedKeys.keys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN7QeIdugZos3HAO/Btzok1BTYLJ7NkCvEAyT2RPQm91"
          ];
          shell = pkgs.zsh;
        };
      };
    };
  };

}
