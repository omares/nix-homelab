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

    # Some tmpfiles rules create ~/.config/<app> and leave the parent owned by root
    systemd.tmpfiles.settings.omares-home."${config.users.users.omares.home}/.config".d = {
      mode = "0755";
      user = "omares";
      group = config.users.users.omares.group;
    };
  };

}
