 NIXPKGS_ALLOW_UNFREE=1 ~/nixstatic shell --impure nixpkgs/25.05#scrcpy -c bash

~/nixstatic run .#vscode
systemctl --user start microvm-virtiofsd-workspace.service
systemctl --user status microvm-virtiofsd-workspace.service
systemctl --user stop microvm-virtiofsd-workspace.service

~/nixstatic run .#microvm

