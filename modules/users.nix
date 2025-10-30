{ config, lib, pkgs, ... }:

{
# Enable sudo without password for wheel group
security.sudo.wheelNeedsPassword = false;

users.users.root = {
password = "root";
};

users.users.dev = {
  isNormalUser = true;
  group = "dev";
  extraGroups = [ "wheel" ];
  password = "dev";
  shell = pkgs.bash;
  uid = 1001;
};

  # Create a matching group
  users.groups.dev = {
    gid = 1001;  # Match your host user's GID
  };


}
