#!/usr/bin/env bash
# Atlassian CLI Installer (quick test version)

set -e

echo "=== Atlassian CLI Installer ==="
echo ""

# Detect OS
if [[ "$OSTYPE" != "linux-gnu"* ]]; then
  echo "❌ Error: This script supports Linux only." >&2
  exit 1
fi

# Detect architecture
ARCH=$(uname -m)
case "$ARCH" in
  x86_64) ARCH="amd64" ;;
  aarch64) ARCH="arm64" ;;
  *)
    echo "❌ Unsupported architecture: $ARCH" >&2
    exit 1
    ;;
esac

# Check for curl
if ! command -v curl &>/dev/null; then
  echo "❌ Error: curl is required. Please install curl and rerun this script." >&2
  exit 1
fi

# Download latest ACLI binary
echo "📦 Downloading latest ACLI binary for $ARCH..."
curl -LO "https://acli.atlassian.com/linux/latest/acli_linux_${ARCH}/acli"

# Make executable
chmod +x ./acli

# Install based on user privileges
if [ "$(id -u)" -eq 0 ]; then
  echo "📍 Installing to /usr/local/bin/acli (root mode)..."
  mv ./acli /usr/local/bin/acli
  INSTALL_PATH="/usr/local/bin/acli"
else
  echo "📍 Installing to ~/.local/bin/acli (user mode)..."
  mkdir -p ~/.local/bin
  mv ./acli ~/.local/bin/acli
  
  # Add to PATH if not already there
  export PATH="$HOME/.local/bin:$PATH"
  if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' ~/.bashrc; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
    echo "✅ Added ~/.local/bin to PATH in ~/.bashrc"
  fi
  
  INSTALL_PATH="$HOME/.local/bin/acli"
fi

echo ""
echo "✅ ACLI installed successfully!"
echo ""
echo "📍 Install location: $INSTALL_PATH"
echo ""

# Verify installation
echo "🔍 Verifying installation..."
if command -v acli &>/dev/null; then
  echo "✅ acli command is available"
  acli --help | head -5 || true
else
  echo "⚠️  acli not in PATH yet. Run: source ~/.bashrc"
fi

echo ""
echo "=== Quick Start ==="
echo ""
echo "1. Test installation:"
echo "   acli --help"
echo ""
echo "2. Authentication (if needed):"
echo "   Visit: https://id.atlassian.com/manage-profile/security/api-tokens"
echo "   Create an API token"
echo "   Run: acli auth login"
echo ""
echo "3. If acli not found, reload your shell:"
echo "   source ~/.bashrc"
echo ""
echo "=== Installation complete! ==="