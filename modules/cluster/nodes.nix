{
  config,
  ...
}:
{

  imports = [
    ./cluster.nix
    ./colmena.nix
  ];

  cluster.nodes = {
    defaults = {
      managed = false;
      roles = [ config.nixosModules.role-default ];
    };

    build-01 = {
      roles = [ config.nixosModules.role-builder ];
      host = "192.168.20.224";
    };

    build-02 = {
      roles = [ config.nixosModules.role-builder ];
      host = "192.168.20.46";
      system = "aarch64-linux";
    };

    dns-01 = {
      roles = [ config.nixosModules.role-dns ];
      host = "192.168.20.47";
    };

    dns-02 = {
      roles = [ config.nixosModules.role-dns ];
      host = "192.168.20.xx";
      system = "aarch64-linux";
    };

    proxy-01 = {
      roles = [ config.nixosModules.role-proxy ];
      sops-vault = [
        "acme"
        "easydns"
      ];
      host = "192.168.20.44";
    };
  };
}
