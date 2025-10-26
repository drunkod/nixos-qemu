{ pkgs, self }:

{
microvm = {
type = "app";
program = "${self.nixosConfigurations.my-microvm.config.microvm.declaredRunner}/bin/microvm-run";
};

# Connect as dev user (recommended)
connect = {
type = "app";
program = toString (pkgs.writeShellScript "connect-vm" ''
echo "🔌 Connecting to MicroVM as 'dev' user..."
echo ""
xhost +local: 2>/dev/null || true

echo "Password: dev"
echo ""

exec ${pkgs.openssh}/bin/ssh \
-X \
-o "ForwardX11Trusted=yes" \
-o "ForwardX11Timeout=596h" \
dev@localhost -p 2222
'');
};

# Connect as root
connect-root = {
type = "app";
program = toString (pkgs.writeShellScript "connect-vm-root" ''
echo "🔌 Connecting to MicroVM as 'root'..."
echo ""
xhost +local: 2>/dev/null || true

echo "Password: root"
echo "⚠️ Use 'code-root' command for VSCode as root"
echo ""

exec ${pkgs.openssh}/bin/ssh \
-X \
-o "ForwardX11Trusted=yes" \
-o "ForwardX11Timeout=596h" \
root@localhost -p 2222
'');
};

# Launch VSCode as dev user
vscode = {
type = "app";
program = toString (pkgs.writeShellScript "launch-vscode" ''
echo "🚀 Launching VSCode as 'dev' user..."
echo ""

xhost +local: 2>/dev/null || true

${pkgs.openssh}/bin/ssh \
-X \
-o "ForwardX11Trusted=yes" \
-o "ForwardX11Timeout=596h" \
dev@localhost -p 2222 \
"code /workspace"
'');
};

# Launch VSCode as root
vscode-root = {
type = "app";
program = toString (pkgs.writeShellScript "launch-vscode-root" ''
echo "🚀 Launching VSCode as root (--no-sandbox)..."
echo ""

xhost +local: 2>/dev/null || true

${pkgs.openssh}/bin/ssh \
-X \
-o "ForwardX11Trusted=yes" \
-o "ForwardX11Timeout=596h" \
root@localhost -p 2222 \
"code --no-sandbox --user-data-dir=/root/.vscode-root /workspace"
'');
};

# Test X11
test-x11 = {
type = "app";
program = toString (pkgs.writeShellScript "test-x11" ''
echo "🧪 Testing X11 Setup..."
echo ""
echo "Host DISPLAY: $DISPLAY"

if [ -z "$DISPLAY" ]; then
echo "❌ No DISPLAY set on host!"
exit 1
fi

echo "✅ Host X11 is running"
echo ""

xhost +local: 2>/dev/null || true

echo "Connecting to VM and testing X11..."
echo ""

${pkgs.openssh}/bin/ssh \
-X \
-o "ForwardX11Trusted=yes" \
dev@localhost -p 2222 \
'echo "VM DISPLAY: $DISPLAY"; xeyes &'

echo ""
echo "If you see eyes 👀, X11 works!"
'');
};
}
