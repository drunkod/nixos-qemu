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
echo "║ Portable Dev Environment with VSCode ║"
echo "╚════════════════════════════════════════╝"
echo ""
echo "📦 VM: 4 CPU | 4GB RAM"
echo "📁 Store: ${customNixStore}"
echo ""
echo "🚀 Quick Start:"
echo " 1. Terminal 1: ~/nixstatic run .#microvm"
echo " 2. Terminal 2: ~/nixstatic run .#connect"
echo ""
echo "📋 Commands:"
echo " ~/nixstatic run .#microvm - Start VM"
echo " ~/nixstatic run .#connect - SSH as 'dev' (recommended)"
echo " ~/nixstatic run .#connect-root - SSH as 'root'"
echo " ~/nixstatic run .#vscode - VSCode as 'dev'"
echo " ~/nixstatic run .#vscode-root - VSCode as root"
echo " ~/nixstatic run .#test-x11 - Test X11"
echo ""
echo "👤 Users:"
echo " dev / dev - Regular user (recommended for VSCode)"
echo " root / root - Admin user (use 'code-root' for VSCode)"
echo ""
echo "💡 Inside VM:"
echo " code /workspace - VSCode (as dev)"
echo " code-root /workspace - VSCode (as root)"
'';
}
