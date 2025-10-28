{ config, lib, pkgs, ... }:

{
nix = {
package = pkgs.nixFlakes;

text

extraOptions = ''
  experimental-features = nix-command flakes
'';

settings = {
  # Enable flakes permanently
  experimental-features = [ "nix-command" "flakes" ];
  
  # Optional: Better build performance
  max-jobs = "auto";
  cores = 0;
  
  # Optional: Save disk space
  auto-optimise-store = true;
};

};
}