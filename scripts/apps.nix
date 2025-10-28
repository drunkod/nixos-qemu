{ pkgs, self }:

{
  microvm = {
    type = "app";
    program = "${self.nixosConfigurations.my-microvm.config.microvm.declaredRunner}/bin/microvm-run";
  };

  # ✨ NEW: VSCode on HOST (FAST!)
  vscode-host = {
    type = "app";
    program = toString (pkgs.writeShellScript "vscode-host" ''
      echo "🚀 Launching VSCode on HOST (fast!)..."
      echo ""
      echo "📁 Workspace: $(pwd)"
      echo "   Shared with VM at: /workspace"
      echo ""
      
      # Launch VSCode natively on host
      ${pkgs.vscode}/bin/code --new-window --no-sandbox "$@"
    '');
  };

  # Quick terminal access to VM
  terminal = {
    type = "app";
    program = toString (pkgs.writeShellScript "vm-terminal" ''
      echo "🔌 Connecting to VM terminal..."
      echo "   Password: dev"
      echo ""
      
      exec ${pkgs.openssh}/bin/ssh \
        -o "StrictHostKeyChecking=no" \
        -o "UserKnownHostsFile=/dev/null" \
        -o "LogLevel=ERROR" \
        -t dev@localhost -p 2222
    '');
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

  # VSCode in VM via X11 (SLOW - for testing only)
  vscode-vm = {
    type = "app";
    program = toString (pkgs.writeShellScript "launch-vscode-vm" ''
      echo "🐢 Launching VSCode IN VM (via X11 - slow)..."
      echo ""
      echo "💡 For better performance, use: ~/nixstatic run .#vscode-host"
      echo ""
      echo "Close VSCode to end the session"
      echo ""
      
      xhost +local: 2>/dev/null || true
      
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

  # Alias: default vscode = host (fast)
  vscode = {
    type = "app";
    program = toString (pkgs.writeShellScript "vscode-default" ''
      echo "🚀 Launching VSCode on HOST (fast!)..."
      echo ""
      echo "📁 Workspace: $(pwd)"
      echo "   Files shared with VM at: /workspace"
      echo ""
      echo "💡 To use VSCode in VM: ~/nixstatic run .#vscode-vm"
      echo ""
      # Add Git to PATH so VSCode can find it
        export PATH="${pkgs.git}/bin:$PATH"
      ${pkgs.vscode}/bin/code --new-window --no-sandbox "$@"
    '');
  };

  vscode-root = {
    type = "app";
    program = toString (pkgs.writeShellScript "launch-vscode-root" ''
      echo "🚀 Launching VSCode as root..."
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
    '');
  };

  test-network = {
    type = "app";
    program = toString (pkgs.writeShellScript "test-network" ''
      echo "🔍 Testing VM Network..."
      
      ${pkgs.openssh}/bin/ssh \
        -o "StrictHostKeyChecking=no" \
        -o "UserKnownHostsFile=/dev/null" \
        -o "LogLevel=ERROR" \
        dev@localhost -p 2222 \
        'bash -c "
          echo \"📡 Network interfaces:\"
          ip addr show | grep -E \"^[0-9]+:|inet \"
          echo \"\"
          
          echo \"🛣️  Routes:\"
          ip route
          echo \"\"
          
          echo \"🔍 DNS config:\"
          cat /etc/resolv.conf
          echo \"\"
          
          echo \"🧪 Tests:\"
          echo -n \"  Ping 8.8.8.8: \"
          ping -c 1 -W 2 8.8.8.8 &>/dev/null && echo \"✅\" || echo \"❌\"
          
          echo -n \"  Ping google.com: \"
          ping -c 1 -W 2 google.com &>/dev/null && echo \"✅\" || echo \"❌\"
          
          echo -n \"  Curl google.com: \"
          curl -s -m 5 https://google.com &>/dev/null && echo \"✅\" || echo \"❌\"
        "'
    '');
  };
}