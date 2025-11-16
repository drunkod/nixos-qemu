NIXPKGS_ALLOW_UNFREE=1 ~/nixstatic shell --impure --offline nixpkgs/25.05#android-tools nixpkgs/25.05#scrcpy -c bash -lc 'set -e; trap "adb shell wm density reset || true" EXIT INT TERM HUP; adb shell wm density 290; scrcpy -Sw -K --no-audio'

run in this dir
unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY no_proxy NO_PROXY && ~/nixstatic run --offline .#chromium

unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY no_proxy NO_PROXY && NIXPKGS_ALLOW_UNFREE=1 ~/nixstatic shell --impure --offline nixpkgs/25.05#chromium -c chromium --new-window --no-sandbox
after this work translate in chrome

unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY no_proxy NO_PROXY && ~/nixstatic run --offline .#vscode


systemctl --user start microvm-virtiofsd-workspace.service
systemctl --user status microvm-virtiofsd-workspace.service
systemctl --user stop microvm-virtiofsd-workspace.service

~/nixstatic run .#microvm

