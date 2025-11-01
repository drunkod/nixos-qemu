 { config, lib, pkgs, ... }:

{
environment.interactiveShellInit = ''
# Proxy settings
PROXY_HOST="192.168.0.10"
PROXY_PORT="3128"
PROXY_URL="http://$PROXY_HOST:$PROXY_PORT"

# Shell functions for proxy control (these actually work!)
enable-proxy() {
  export http_proxy="$PROXY_URL"
  export https_proxy="$PROXY_URL"
  export HTTP_PROXY="$PROXY_URL"
  export HTTPS_PROXY="$PROXY_URL"
  export no_proxy="localhost,127.0.0.1,::1,192.168.0.0/24,*.chelib.local,*.chelib.ru"
  export NO_PROXY="$no_proxy"
  echo "✅ Proxy enabled: $PROXY_URL"
  echo "💡 Test: curl -I https://google.com"
}

disable-proxy() {
  unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY no_proxy NO_PROXY
  echo "✅ Proxy disabled - using direct connection"
  echo "💡 Test: curl -I https://google.com"
}

detect-proxy() {
  if ${pkgs.netcat}/bin/nc -z -w2 $PROXY_HOST $PROXY_PORT 2>/dev/null; then
    echo "🔌 Corporate proxy detected"
    enable-proxy
  else
    echo "📱 Direct connection detected"
    disable-proxy
  fi
}

# Detect network mode for display
if ${pkgs.netcat}/bin/nc -z -w2 192.168.0.10 3128 2>/dev/null; then
  NETWORK_MODE="🔌 Corporate (proxy available - use 'enable-proxy')"
else
  NETWORK_MODE="📱 Direct/Phone Hotspot"
fi

if [ -n "$SSH_CONNECTION" ]; then
  echo "✅ Connected via SSH"
  echo "👤 User: $(whoami)"
  echo "🌐 Network: $NETWORK_MODE"
  echo "🖥️  DISPLAY=$DISPLAY"
  echo ""
  if [ "$(whoami)" = "root" ]; then
    echo "Test X11: xeyes &"
    echo "VSCode: code-root /workspace"
    echo ""
    echo "💡 Tip: Login as 'dev' user for regular VSCode:"
    echo "   ssh -X dev@localhost -p 2222"
  else
    echo "Test X11: xeyes &"
    echo "VSCode: code /workspace"
    echo ""
    echo "🌐 Proxy Commands:"
    echo "   enable-proxy  - Enable corporate proxy"
    echo "   disable-proxy - Use direct connection"
    echo "   detect-proxy  - Auto-detect and configure"
  fi
else
  echo "⚠️  Direct console - X11 won't work!"
  echo "   Use: ssh -X dev@localhost -p 2222"
fi

'';
}