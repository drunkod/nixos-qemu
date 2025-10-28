{ config, lib, pkgs, customNixStore, workspaceSource, ... }:

{
  nixpkgs.config.allowUnfree = true;

  microvm = {
    hypervisor = "qemu";
    vcpu = 4;
    mem = 4096;
    
    # User mode networking with DNS
    interfaces = [{
      type = "user";
      id = "vm0";
      mac = "02:00:00:00:00:01";
    }];

    forwardPorts = [
      { from = "host"; host.port = 8083; guest.port = 8083; }
      { from = "host"; host.port = 2222; guest.port = 22; }
      { from = "host"; host.port = 3000; guest.port = 3000; }
    ];

    socket = "/tmp/nixos-microvm-control.socket";

    shares = [
      {
        source = customNixStore;
        mountPoint = "/nix/.ro-store";
        tag = "ro-store";
        proto = "9p";
        securityModel = "none";
      }
  {
    source = workspaceSource;
    mountPoint = "/workspace";
    tag = "workspace";
    proto = "9p";
    securityModel = "none";
  }
    ];
  };

  system.stateVersion = "25.05";
}