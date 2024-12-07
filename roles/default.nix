{ nixpkgs, homelabLib, ... }:
{
  meta = {
    nixpkgs = import nixpkgs {
      system = "x86_64-linux";
    };
    #          _module.args = {
    #            inherit homelabLib;
    #          };
  };

  defaults = {
    deployment = {
      targetUser = "omares";
    };
    imports = [
      ./defaults
    ];
  };

  build-01 = {
    deployment = {
      targetHost = "192.168.20.224";
    };
    imports = [
      ./builder
    ];
  };
  #  defaults = lib.mkNode {
  #    roles = [ ];
  #    deployment = {
  #      targetUser = "omares";
  #    };
  #  };
  #
  #  pmx = lib.mkNode {
  #    roles = [
  #      lib.roles.pmx
  #      lib.roles.dns
  #    ];
  #    deployment = {
  #      targetHost = "192.168.20.47";
  #    };
  #  };
  #
  #  build-01 = lib.mkNode {
  #    roles = [
  #      lib.roles.builder
  #      lib.roles.defaults
  #    ];
  #    deployment = {
  #      targetHost = "192.168.20.224";
  #    };
  #  };
  #
  #  dns-01 = lib.mkNode {
  #    roles = [
  #      lib.roles.dns
  #    ];
  #    deployment = {
  #      targetHost = "192.168.20.47";
  #    };
  #  };
  #
  #  dns-02 = lib.mkNode {
  #    nixpkgs.system = "aarch64-linux";
  #
  #    roles = [
  #      lib.roles.dns
  #    ];
  #    deployment = {
  #      targetHost = "192.168.20.47";
  #    };
  #  };
}
