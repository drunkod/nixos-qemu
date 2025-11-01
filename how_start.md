 NIXPKGS_ALLOW_UNFREE=1 ~/nixstatic shell --impure nixpkgs/25.05#scrcpy -c bash

unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY no_proxy NO_PROXY && ~/nixstatic run .#vscode
unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY no_proxy NO_PROXY && ~/nixstatic run .#chromium

systemctl --user start microvm-virtiofsd-workspace.service
systemctl --user status microvm-virtiofsd-workspace.service
systemctl --user stop microvm-virtiofsd-workspace.service

~/nixstatic run .#microvm

