{ pkgs, config, ... }:
{

  config = {
    ids.uids = {
      omares = 3002;
    };

    users = {
      defaultUserShell = pkgs.zsh;
      mutableUsers = false;
      users = {
        omares = {
          uid = config.ids.uids.omares;
          extraGroups = [ "wheel" ];
          hashedPassword = "$6$lCrk5LrSmlHP9OuU$cdAJDWHx71cNXktmtegOT8qisplgE2INYBO7FTYBQmXVU0l29Xqbh0JxCUBg.MvZ/z4VpLZrIht7jf0hwPqxR0";
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
