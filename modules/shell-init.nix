{ config, lib, pkgs, ... }:

{
environment.interactiveShellInit = ''
if [ -n "$SSH_CONNECTION" ]; then
echo "✅ Connected via SSH"
echo " User: $(whoami)"
echo " DISPLAY=$DISPLAY"
echo ""
if [ "$(whoami)" = "root" ]; then
echo "Test X11: xeyes &"
echo "VSCode: code-root /workspace"
echo ""
echo "💡 Tip: Login as 'dev' user for regular VSCode:"
echo " ssh -X dev@localhost -p 2222"
else
echo "Test X11: xeyes &"
echo "VSCode: code /workspace"
fi
else
echo "⚠️ Direct console - X11 won't work!"
echo " Use: ssh -X dev@localhost -p 2222"
fi
'';
}
