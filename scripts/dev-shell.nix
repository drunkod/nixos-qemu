{ pkgs, ops, customNixStore }:

pkgs.mkShell {
  buildInputs = [
    ops
    pkgs.qemu
    pkgs.nodejs
    pkgs.git
    pkgs.vscode  # Add VSCode to dev shell
  ];
  
  shellHook = ''
    echo "╔════════════════════════════════════════╗"
    echo "║  Portable Dev Environment with VSCode  ║"
    echo "╚════════════════════════════════════════╝"
    echo ""
    echo "📦 VM: 4 CPU | 4GB RAM"
    echo "📁 Store: ${customNixStore}"
    echo ""
    echo "🚀 Quick Start:"
    echo "   Terminal 1: ~/nixstatic run .#microvm"
    echo "   Terminal 2: ~/nixstatic run .#vscode"
    echo ""
    echo "📋 VSCode Options:"
    echo "   ~/nixstatic run .#vscode         - ⚡ Host (FAST!)"
    echo "   ~/nixstatic run .#vscode-host    - ⚡ Host (explicit)"
    echo "   ~/nixstatic run .#vscode-vm      - 🐢 VM via X11 (slow)"
    echo ""
    echo "📋 VM Access:"
    echo "   ~/nixstatic run .#terminal       - Quick terminal"
    echo "   ~/nixstatic run .#connect        - SSH with X11"
    echo ""
    echo "🧪 Testing:"
    echo "   ~/nixstatic run .#test-network   - Test internet"
    echo "   ~/nixstatic run .#test-x11       - Test X11"
    echo "   ~/nixstatic run .#test-vscode    - Test VSCode in VM"
    echo ""
    echo "💡 Recommended workflow:"
    echo "   - Edit: VSCode on host (fast!)"
    echo "   - Run:  Terminal in VM"
    echo "   - Files auto-shared via /workspace"
  '';
}