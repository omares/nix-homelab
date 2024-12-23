{
  config,
  ...
}:
{

  cluster.nodes = {
    build-01 = {
      roles = [ config.flake.nixosModules.role-builder ];
      host = "192.168.20.224";
    };

    build-02 = {
      roles = [ config.flake.nixosModules.role-builder ];
      host = "192.168.20.46";
      system = "aarch64-linux";
    };

    dns-01 = {
      roles = [ config.flake.nixosModules.role-dns ];
      host = "192.168.20.29";
    };

    dns-02 = {
      roles = [ config.flake.nixosModules.role-dns ];
      host = "192.168.20.xx";
      system = "aarch64-linux";
    };

    proxy-01 = {
      roles = [ config.flake.nixosModules.role-proxy ];
      host = "192.168.20.44";
    };
  };
}
