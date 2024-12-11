{
  homelabLib,
  ...
}:
{

  # imports = [
  #   ../modules/cluster/cluster.nix
  # ];

  cluster.nodes = {
    defaults = {
      managed = false;
      roles = [ homelabLib.roles.defaults ];
    };

    build-01 = {
      roles = [ homelabLib.roles.builder ];
      host = "192.168.20.224";
    };

    build-02 = {
      roles = [ homelabLib.roles.builder ];
      host = "192.168.20.46";
      system = "aarch64-linux";
    };

    dns-01 = {
      roles = [ homelabLib.roles.dns ];
      host = "192.168.20.47";
    };

    dns-02 = {
      roles = [ homelabLib.roles.dns ];
      host = "192.168.20.xx";
      system = "aarch64-linux";
    };

    proxy-01 = {
      roles = [ homelabLib.roles.proxy ];
      sops-vault = [
        "acme"
        "easydns"
      ];
      host = "192.168.20.44";
    };
  };

  # localFlake.nixosConfigurations = cluster.nodes;

}
