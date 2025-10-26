{ pkgs, ops, customNixStore }:

pkgs.mkShell {
  buildInputs = [
    ops
    pkgs.qemu
    pkgs.nodejs
    pkgs.git
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
    echo "   1. Terminal 1: ~/nixstatic run .#microvm"
    echo "   2. Terminal 2: ~/nixstatic run .#vscode"
    echo ""
    echo "📋 Commands:"
    echo "   ~/nixstatic run .#microvm         - Start VM"
    echo "   ~/nixstatic run .#vscode          - VSCode (waits for exit)"
    echo "   ~/nixstatic run .#vscode-bg       - VSCode (background)"
    echo "   ~/nixstatic run .#connect         - SSH shell"
    echo ""
    echo "🐛 Debug:"
    echo "   ~/nixstatic run .#test-x11        - Test X11"
    echo "   ~/nixstatic run .#test-vscode     - Test installation"
    echo "   ~/nixstatic run .#vscode-debug    - Verbose launch"
    echo ""
    echo "💡 How it works:"
    echo "   - VSCode runs in VM, displays on your screen"
    echo "   - SSH tunnel must stay open for X11"
    echo "   - Close VSCode to end the session"
  '';
}