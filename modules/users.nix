{ config, lib, pkgs, ... }:

{
# Enable sudo without password for wheel group
security.sudo.wheelNeedsPassword = false;

users.users.root = {
password = "root";
};

users.users.dev = {
isNormalUser = true;
extraGroups = [ "wheel" ];
password = "dev";
shell = pkgs.bash;
};
}
