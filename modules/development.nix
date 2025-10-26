{ config, lib, pkgs, ... }:

{
programs.git = {
enable = true;
config = {
init.defaultBranch = "main";
safe.directory = "/workspace";
};
};

environment.systemPackages = with pkgs; [
# Editors
vim
nano

# Version control
git

# Development tools
nodejs_22
python3

# GUI applications
vscode

# X11 utilities
xorg.xauth
xorg.xhost
xorg.xeyes

# Network tools
curl
wget
netcat

# System utilities
htop
tree
file

# VSCode wrapper for root
(pkgs.writeScriptBin "vscode-root" ''
#!/bin/sh
exec ${pkgs.vscode}/bin/code --no-sandbox --user-data-dir=/root/.vscode-root "$@"
'')
];

# Shell aliases
environment.shellAliases = {
code-root = "code --no-sandbox --user-data-dir=/root/.vscode-root";
};
}
