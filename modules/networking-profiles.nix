{ config, lib, pkgs, ... }:

let
  # Proxy settings
  proxyHost = "192.168.0.10";
  proxyPort = "3128";
  proxyUrl = "http://${proxyHost}:${proxyPort}";
  
  # Auto-detect script - prints commands to eval
  detectProxy = pkgs.writeShellScriptBin "detect-proxy" ''
    # Check if proxy is reachable
    if ${pkgs.netcat}/bin/nc -z -w2 ${proxyHost} ${proxyPort} 2>/dev/null; then
      echo "🔌 Corporate proxy detected: ${proxyUrl}" >&2
      echo "export http_proxy='${proxyUrl}'"
      echo "export https_proxy='${proxyUrl}'"
      echo "export HTTP_PROXY='${proxyUrl}'"
      echo "export HTTPS_PROXY='${proxyUrl}'"
      echo "export no_proxy='localhost,127.0.0.1,::1,192.168.0.0/24,*.chelib.local,*.chelib.ru'"
      echo "export NO_PROXY='localhost,127.0.0.1,::1,192.168.0.0/24,*.chelib.local,*.chelib.ru'"
    else
      echo "📱 Direct connection (phone hotspot?)" >&2
      echo "unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY no_proxy NO_PROXY"
    fi
  '';

  # Manual proxy enable - prints commands to eval
  enableProxy = pkgs.writeShellScriptBin "enable-proxy" ''
    echo "✅ Proxy enabled: ${proxyUrl}" >&2
    echo "💡 Test with: curl -I https://google.com" >&2
    echo ""
    echo "export http_proxy='${proxyUrl}'"
    echo "export https_proxy='${proxyUrl}'"
    echo "export HTTP_PROXY='${proxyUrl}'"
    echo "export HTTPS_PROXY='${proxyUrl}'"
    echo "export no_proxy='localhost,127.0.0.1,::1,192.168.0.0/24,*.chelib.local,*.chelib.ru'"
    echo "export NO_PROXY='localhost,127.0.0.1,::1,192.168.0.0/24,*.chelib.local,*.chelib.ru'"
  '';

  # Manual proxy disable - prints commands to eval
  disableProxy = pkgs.writeShellScriptBin "disable-proxy" ''
    echo "✅ Proxy disabled - using direct connection" >&2
    echo "💡 Test with: curl -I https://google.com" >&2
    echo ""
    echo "unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY no_proxy NO_PROXY"
  '';

in {
  # Add detection and control scripts
  environment.systemPackages = [ 
    detectProxy 
    enableProxy 
    disableProxy
  ];
}