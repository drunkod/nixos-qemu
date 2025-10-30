{ config, lib, pkgs, ... }:

{
  environment.interactiveShellInit = ''
    # Detect network mode
    if ${pkgs.netcat}/bin/nc -z -w2 192.168.0.10 3128 2>/dev/null; then
      NETWORK_MODE="🔌 Corporate (via proxy)"
    else
      NETWORK_MODE="📱 Direct/Phone Hotspot"
    fi

    if [ -n "$SSH_CONNECTION" ]; then
      echo "✅ Connected via SSH"
      echo " User: $(whoami)"
      echo " Network: $NETWORK_MODE"
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
        echo ""
        echo "🌐 Network Commands:"
        echo "   detect-proxy  - Auto-detect and configure"
        echo "   enable-proxy  - Force proxy mode"
        echo "   disable-proxy - Force direct mode"
      fi
    else
      echo "⚠️ Direct console - X11 won't work!"
      echo " Use: ssh -X dev@localhost -p 2222"
    fi
  '';
}