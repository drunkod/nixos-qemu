{ pkgs, self }:

{
  microvm = {
    type = "app";
    program = "${self.nixosConfigurations.my-microvm.config.microvm.declaredRunner}/bin/microvm-run";
  };

  connect = {
    type = "app";
    program = toString (pkgs.writeShellScript "connect-vm" ''
      echo "🔌 Connecting to MicroVM as 'dev' user..."
      echo ""
      xhost +local: 2>/dev/null || true
      
      echo "Password: dev"
      echo ""
      
      exec ${pkgs.openssh}/bin/ssh \
        -o "StrictHostKeyChecking=no" \
        -o "UserKnownHostsFile=/dev/null" \
        -o "LogLevel=ERROR" \
        -X \
        -o "ForwardX11Trusted=yes" \
        -o "ForwardX11Timeout=596h" \
        dev@localhost -p 2222
    '');
  };

  connect-root = {
    type = "app";
    program = toString (pkgs.writeShellScript "connect-vm-root" ''
      echo "🔌 Connecting to MicroVM as 'root'..."
      echo ""
      xhost +local: 2>/dev/null || true
      
      echo "Password: root"
      echo "⚠️  Use 'code-root' command for VSCode as root"
      echo ""
      
      exec ${pkgs.openssh}/bin/ssh \
        -o "StrictHostKeyChecking=no" \
        -o "UserKnownHostsFile=/dev/null" \
        -o "LogLevel=ERROR" \
        -X \
        -o "ForwardX11Trusted=yes" \
        -o "ForwardX11Timeout=596h" \
        root@localhost -p 2222
    '');
  };

  # Launch VSCode as dev user - FIXED VERSION
  vscode = {
    type = "app";
    program = toString (pkgs.writeShellScript "launch-vscode" ''
      echo "🚀 Launching VSCode as 'dev' user..."
      echo ""
      echo "💡 VSCode will open in a new window"
      echo "   Close VSCode to end the session"
      echo ""
      
      xhost +local: 2>/dev/null || true
      
      # Use --wait to keep SSH connection alive
      ${pkgs.openssh}/bin/ssh \
        -o "StrictHostKeyChecking=no" \
        -o "UserKnownHostsFile=/dev/null" \
        -o "LogLevel=ERROR" \
        -X \
        -o "ForwardX11Trusted=yes" \
        -o "ForwardX11Timeout=596h" \
        dev@localhost -p 2222 \
        'code --wait /workspace'
      
      echo ""
      echo "✅ VSCode closed"
    '');
  };

  # Alternative: Launch VSCode in background (keeps SSH open)
  vscode-bg = {
    type = "app";
    program = toString (pkgs.writeShellScript "launch-vscode-bg" ''
      echo "🚀 Launching VSCode in background..."
      echo ""
      echo "💡 Press Ctrl+C to close the SSH tunnel"
      echo "   (VSCode will close when you do this)"
      echo ""
      
      xhost +local: 2>/dev/null || true
      
      # Launch VSCode and keep SSH alive
      ${pkgs.openssh}/bin/ssh \
        -o "StrictHostKeyChecking=no" \
        -o "UserKnownHostsFile=/dev/null" \
        -o "LogLevel=ERROR" \
        -X \
        -o "ForwardX11Trusted=yes" \
        -o "ForwardX11Timeout=596h" \
        dev@localhost -p 2222 \
        'code /workspace; echo "VSCode launched. Press Ctrl+C to exit..."; sleep infinity'
      
      echo ""
      echo "✅ SSH session closed"
    '');
  };

  # Launch VSCode as root
  vscode-root = {
    type = "app";
    program = toString (pkgs.writeShellScript "launch-vscode-root" ''
      echo "🚀 Launching VSCode as root..."
      echo ""
      echo "💡 Close VSCode to end the session"
      echo ""
      
      xhost +local: 2>/dev/null || true
      
      ${pkgs.openssh}/bin/ssh \
        -o "StrictHostKeyChecking=no" \
        -o "UserKnownHostsFile=/dev/null" \
        -o "LogLevel=ERROR" \
        -X \
        -o "ForwardX11Trusted=yes" \
        -o "ForwardX11Timeout=596h" \
        root@localhost -p 2222 \
        'code --no-sandbox --user-data-dir=/root/.vscode-root --wait /workspace'
      
      echo ""
      echo "✅ VSCode closed"
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
        -o "StrictHostKeyChecking=no" \
        -o "UserKnownHostsFile=/dev/null" \
        -o "LogLevel=ERROR" \
        -X \
        -o "ForwardX11Trusted=yes" \
        dev@localhost -p 2222 \
        'echo "VM DISPLAY: $DISPLAY"; xeyes &'
      
      echo ""
      echo "If you see eyes 👀, X11 works!"
    '');
  };

  # Simple test to check VSCode installation
  test-vscode = {
    type = "app";
    program = toString (pkgs.writeShellScript "test-vscode" ''
      echo "🧪 Testing VSCode installation in VM..."
      echo ""
      
      echo "📋 Checking as dev user:"
      ${pkgs.openssh}/bin/ssh \
        -o "StrictHostKeyChecking=no" \
        -o "UserKnownHostsFile=/dev/null" \
        -o "LogLevel=ERROR" \
        dev@localhost -p 2222 \
        'bash -c "
          echo \"  PATH: \$PATH\"
          echo \"\"
          if command -v code &> /dev/null; then
            echo \"  ✅ code found: \$(which code)\"
            echo \"  Version: \$(code --version 2>&1 | head -1)\"
          else
            echo \"  ❌ code NOT found\"
          fi
        "'
      
      echo ""
      echo "📋 Checking as root user:"
      ${pkgs.openssh}/bin/ssh \
        -o "StrictHostKeyChecking=no" \
        -o "UserKnownHostsFile=/dev/null" \
        -o "LogLevel=ERROR" \
        root@localhost -p 2222 \
        'bash -c "
          echo \"  PATH: \$PATH\"
          echo \"\"
          if command -v code &> /dev/null; then
            echo \"  ✅ code found: \$(which code)\"
            echo \"  Version: \$(code --version 2>&1 | head -1)\"
          else
            echo \"  ❌ code NOT found\"
          fi
        "'
    '');
  };

  # Debug version with verbose output
  vscode-debug = {
    type = "app";
    program = toString (pkgs.writeShellScript "launch-vscode-debug" ''
      echo "🐛 DEBUG: Launching VSCode with full verbosity..."
      echo ""
      
      xhost +local: 2>/dev/null || true
      
      echo "📋 Host environment:"
      echo "  DISPLAY: $DISPLAY"
      echo "  USER: $USER"
      echo ""
      
      echo "📋 Testing SSH connection..."
      ${pkgs.openssh}/bin/ssh \
        -o "StrictHostKeyChecking=no" \
        -o "UserKnownHostsFile=/dev/null" \
        -o "LogLevel=ERROR" \
        dev@localhost -p 2222 \
        'echo "✅ SSH connection OK"' || {
          echo "❌ SSH connection failed!"
          exit 1
        }
      
      echo ""
      echo "📋 Testing X11 forwarding..."
      ${pkgs.openssh}/bin/ssh \
        -X \
        -o "StrictHostKeyChecking=no" \
        -o "UserKnownHostsFile=/dev/null" \
        -o "LogLevel=ERROR" \
        -o "ForwardX11Trusted=yes" \
        dev@localhost -p 2222 \
        'echo "  DISPLAY: $DISPLAY"' || {
          echo "❌ X11 forwarding failed!"
          exit 1
        }
      
      echo ""
      echo "📋 Checking code binary in VM..."
      ${pkgs.openssh}/bin/ssh \
        -o "StrictHostKeyChecking=no" \
        -o "UserKnownHostsFile=/dev/null" \
        -o "LogLevel=ERROR" \
        dev@localhost -p 2222 \
        'ls -lh $(which code) 2>&1' || {
          echo "❌ code binary not found!"
          exit 1
        }
      
      echo ""
      echo "📋 Launching VSCode (keeping SSH open)..."
      ${pkgs.openssh}/bin/ssh \
        -o "StrictHostKeyChecking=no" \
        -o "UserKnownHostsFile=/dev/null" \
        -o "LogLevel=ERROR" \
        -X \
        -o "ForwardX11Trusted=yes" \
        -o "ForwardX11Timeout=596h" \
        dev@localhost -p 2222 \
        'bash -lc "
          echo \"Starting VSCode...\"
          code --verbose --wait /workspace 2>&1
        "'
      
      echo ""
      echo "✅ VSCode session ended (exit code: $?)"
    '');
  };
}