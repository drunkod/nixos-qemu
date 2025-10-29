{ config, lib, pkgs, ... }:

{
  networking = {
    hostName = "nixos-dev";

    proxy = {
      default = "http://192.168.0.10:3128";
      noProxy = "*.localhost,127.0.0.1,::1,192.168.0.0/24,*.chelib.local,*.chelib.ru";
    };    
    
    # Use DHCP for automatic configuration
    useDHCP = lib.mkDefault true;
    
    # Fallback DNS servers (Google and Cloudflare)
    nameservers = [ "8.8.8.8" "8.8.4.4" "1.1.1.1" ];
    
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 8083 3000 ];
      # Allow all outbound connections
      checkReversePath = false;
    };
  };

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "yes";
      X11Forwarding = true;
      X11UseLocalhost = true;
    };
  };

  # Enable systemd-resolved for DNS
  services.resolved = {
    enable = true;
    dnssec = "false";
    fallbackDns = [ "8.8.8.8" "8.8.4.4" "1.1.1.1" ];
  };
}