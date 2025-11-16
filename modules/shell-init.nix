{ config, lib, pkgs, ... }:

{
environment.interactiveShellInit = ''
# Default proxy settings
PROXY_HOST="192.168.0.10"
PROXY_PORT="3128"
PROXY_URL="http://$PROXY_HOST:$PROXY_PORT"

# Custom proxy configuration file
PROXY_CONFIG="$HOME/.proxy-config"

# Load saved proxy if exists
if [ -f "$PROXY_CONFIG" ]; then
  source "$PROXY_CONFIG"
fi

# Set custom proxy address
set-proxy() {
  if [ -z "$1" ] || [ -z "$2" ]; then
    echo "❌ Usage: set-proxy <host> <port>"
    echo ""
    echo "Examples:"
    echo "  set-proxy 192.168.0.10 3128"
    echo "  set-proxy proxy.company.com 8080"
    echo "  set-proxy 10.0.0.1 3128"
    return 1
  fi
  
  local CUSTOM_HOST="$1"
  local CUSTOM_PORT="$2"
  local CUSTOM_URL="http://$CUSTOM_HOST:$CUSTOM_PORT"
  
  export http_proxy="$CUSTOM_URL"
  export https_proxy="$CUSTOM_URL"
  export HTTP_PROXY="$CUSTOM_URL"
  export HTTPS_PROXY="$CUSTOM_URL"
  export no_proxy="localhost,127.0.0.1,::1,192.168.0.0/24,*.chelib.local,*.chelib.ru"
  export NO_PROXY="$no_proxy"
  
  echo "✅ Custom proxy enabled: $CUSTOM_URL"
  echo "💡 Test: curl -I https://google.com"
  echo ""
  echo "💾 To save for future sessions: save-proxy $CUSTOM_HOST $CUSTOM_PORT"
}

# Save custom proxy to config file
save-proxy() {
  if [ -z "$1" ] || [ -z "$2" ]; then
    echo "❌ Usage: save-proxy <host> <port>"
    echo ""
    echo "Examples:"
    echo "  save-proxy 192.168.0.10 3128"
    echo "  save-proxy proxy.company.com 8080"
    return 1
  fi
  
  local CUSTOM_HOST="$1"
  local CUSTOM_PORT="$2"
  
  cat > "$PROXY_CONFIG" <<EOF
# Saved proxy configuration
PROXY_HOST="$CUSTOM_HOST"
PROXY_PORT="$CUSTOM_PORT"
PROXY_URL="http://$CUSTOM_HOST:$CUSTOM_PORT"
EOF
  
  echo "✅ Proxy saved: http://$CUSTOM_HOST:$CUSTOM_PORT"
  echo "📝 Config file: $PROXY_CONFIG"
  echo ""
  echo "💡 Now you can use 'enable-proxy' to activate saved proxy"
  echo "   Or 'set-proxy $CUSTOM_HOST $CUSTOM_PORT' in new sessions"
}

# Show current proxy configuration
show-proxy() {
  echo "📋 Current Proxy Configuration:"
  echo ""
  
  if [ -f "$PROXY_CONFIG" ]; then
    echo "💾 Saved proxy (from $PROXY_CONFIG):"
    cat "$PROXY_CONFIG" | grep -E "PROXY_HOST|PROXY_PORT|PROXY_URL"
    echo ""
  else
    echo "💾 No saved proxy configuration"
    echo "   Default: http://$PROXY_HOST:$PROXY_PORT"
    echo ""
  fi
  
  if [ -n "$http_proxy" ]; then
    echo "✅ Active proxy:"
    echo "   http_proxy:  $http_proxy"
    echo "   https_proxy: $https_proxy"
    echo "   no_proxy:    $no_proxy"
  else
    echo "❌ No active proxy (direct connection)"
  fi
  echo ""
  
  echo "💡 Commands:"
  echo "   set-proxy <host> <port>  - Set custom proxy (temporary)"
  echo "   save-proxy <host> <port> - Save proxy for future use"
  echo "   enable-proxy             - Enable saved/default proxy"
  echo "   disable-proxy            - Disable proxy"
}

# Clear saved proxy configuration
clear-saved-proxy() {
  if [ -f "$PROXY_CONFIG" ]; then
    rm "$PROXY_CONFIG"
    echo "✅ Saved proxy configuration cleared"
    echo "   Default proxy: http://$PROXY_HOST:$PROXY_PORT"
  else
    echo "ℹ️  No saved proxy configuration to clear"
  fi
}

# Enable proxy (uses saved or default)
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

# Disable proxy
disable-proxy() {
  unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY no_proxy NO_PROXY
  echo "✅ Proxy disabled - using direct connection"
  echo "💡 Test: curl -I https://google.com"
}

# Auto-detect proxy
detect-proxy() {
  if ${pkgs.netcat}/bin/nc -z -w2 $PROXY_HOST $PROXY_PORT 2>/dev/null; then
    echo "🔌 Corporate proxy detected at $PROXY_HOST:$PROXY_PORT"
    enable-proxy
  else
    echo "📱 Direct connection detected"
    disable-proxy
  fi
}

# Quick proxy test
test-proxy() {
  echo "🧪 Testing proxy connectivity..."
  echo ""
  
  if [ -z "$http_proxy" ]; then
    echo "⚠️  No proxy currently enabled"
    echo "   Enable with: enable-proxy"
    echo "   Or set custom: set-proxy <host> <port>"
    echo ""
  else
    echo "Current proxy: $http_proxy"
    echo ""
  fi
  
  echo "Testing connection to google.com..."
  if curl -s -m 5 -I https://google.com >/dev/null 2>&1; then
    echo "✅ Connection successful"
  else
    echo "❌ Connection failed"
    if [ -n "$http_proxy" ]; then
      echo "💡 Try: disable-proxy"
    else
      echo "💡 Try: enable-proxy"
    fi
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
    echo "   set-proxy <host> <port>  - Set custom proxy"
    echo "   save-proxy <host> <port> - Save proxy settings"
    echo "   enable-proxy             - Enable saved/default proxy"
    echo "   disable-proxy            - Disable proxy"
    echo "   detect-proxy             - Auto-detect and configure"
    echo "   show-proxy               - Show current settings"
    echo "   test-proxy               - Test connection"
  fi
else
  echo "⚠️  Direct console - X11 won't work!"
  echo "   Use: ssh -X dev@localhost -p 2222"
fi

'';
}