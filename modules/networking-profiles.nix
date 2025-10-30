{ config, lib, pkgs, ... }:

let
  # Proxy settings
  proxyHost = "192.168.0.10";
  proxyPort = "3128";
  proxyUrl = "http://${proxyHost}:${proxyPort}";
  
  # Auto-detect script
  detectProxy = pkgs.writeShellScriptBin "detect-proxy" ''
    # Check if proxy is reachable
    if ${pkgs.netcat}/bin/nc -z -w2 ${proxyHost} ${proxyPort} 2>/dev/null; then
      echo "🔌 Corporate proxy detected: ${proxyUrl}"
      export http_proxy="${proxyUrl}"
      export https_proxy="${proxyUrl}"
      export HTTP_PROXY="${proxyUrl}"
      export HTTPS_PROXY="${proxyUrl}"
      export no_proxy="localhost,127.0.0.1,::1,192.168.0.0/24,*.chelib.local,*.chelib.ru"
      export NO_PROXY="$no_proxy"
    else
      echo "📱 Direct connection (phone hotspot?)"
      unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY
    fi
  '';

  # Manual proxy enable/disable scripts
  enableProxy = pkgs.writeShellScriptBin "enable-proxy" ''
    export http_proxy="${proxyUrl}"
    export https_proxy="${proxyUrl}"
    export HTTP_PROXY="${proxyUrl}"
    export HTTPS_PROXY="${proxyUrl}"
    export no_proxy="localhost,127.0.0.1,::1,192.168.0.0/24,*.chelib.local,*.chelib.ru"
    export NO_PROXY="$no_proxy"
    echo "✅ Proxy enabled: ${proxyUrl}"
    echo "Test: curl -I https://google.com"
  '';

  disableProxy = pkgs.writeShellScriptBin "disable-proxy" ''
    unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY no_proxy NO_PROXY
    echo "✅ Proxy disabled - using direct connection"
    echo "Test: curl -I https://google.com"
  '';

in {
  # Add detection and control scripts
  environment.systemPackages = [ 
    detectProxy 
    enableProxy 
    disableProxy
  ];

  # Auto-detect proxy on shell start
  environment.interactiveShellInit = ''
    # Auto-detect and configure proxy
    if ${pkgs.netcat}/bin/nc -z -w2 ${proxyHost} ${proxyPort} 2>/dev/null; then
      export http_proxy="${proxyUrl}"
      export https_proxy="${proxyUrl}"
      export HTTP_PROXY="${proxyUrl}"
      export HTTPS_PROXY="${proxyUrl}"
      export no_proxy="localhost,127.0.0.1,::1,192.168.0.0/24,*.chelib.local,*.chelib.ru"
      export NO_PROXY="$no_proxy"
    fi
  '';

  # Configure Nix to use proxy (conditional)
  nix.settings = {
    # These will be ignored if not set
    http-proxy = lib.mkDefault null;
    https-proxy = lib.mkDefault null;
  };

  # System-wide proxy for services (conditional)
  networking.proxy = lib.mkIf (builtins.pathExists "/etc/use-proxy") {
    default = proxyUrl;
    noProxy = "localhost,127.0.0.1,::1,192.168.0.0/24,*.chelib.local,*.chelib.ru";
  };
}