{ config, lib, pkgs, ... }:

{
networking = {
hostName = "nixos-dev";
firewall = {
enable = true;
allowedTCPPorts = [ 22 8083 3000 ];
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
}
