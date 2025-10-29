{ config, lib, pkgs, customNixStore, workspaceSource, ... }:

{
  nixpkgs.config.allowUnfree = true;

  microvm = {
    hypervisor = "qemu";
    vcpu = 4;
    mem = 4096;

    # ✨ ADD THIS: Enable writable Nix store in VM
    writableStoreOverlay = "/nix/.rw-store";

    # VM's own writable Nix store
    volumes = [{
      image = "nix-store.img";
      mountPoint = "/nix";
      size = 40480;  # 40GB
    }];

    interfaces = [{
      type = "user";
      id = "vm0";
      mac = "02:00:00:00:00:01";
    }];

    forwardPorts = [
      { from = "host"; host.port = 8083; guest.port = 8083; }
      { from = "host"; host.port = 2222; guest.port = 22; }
      { from = "host"; host.port = 3000; guest.port = 3000; }
      { from = "host"; host.port = 5173; guest.port = 5173; }
      { from = "host"; host.port = 8080; guest.port = 8080; }
    ];

    socket = "/tmp/nixos-microvm-control.socket";

    shares = [
      # ❌ REMOVE OR COMMENT OUT the host-store share
      # It was mounting read-only store over your writable volume
      # {
      #   source = customNixStore;
      #   mountPoint = "/mnt/host-store";
      #   tag = "host-store";
      #   proto = "9p";
      #   securityModel = "none";
      # }
      
      # ✅ KEEP: Workspace share
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