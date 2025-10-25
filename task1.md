# Refactored Modular Structure

Here's a clean, modular organization:

## Directory Structure

```
nixos-qemu/
├── flake.nix                 # Main flake (thin, imports modules)
├── package.nix              # Ops package
├── config.json              # App config
├── hi.js                    # Test app
├── modules/                 # NixOS modules
│   ├── microvm-hardware.nix # MicroVM & hardware config
│   ├── networking.nix       # Network, SSH, firewall
│   ├── users.nix           # User accounts
│   ├── development.nix     # Dev tools & packages
│   └── shell-init.nix      # Welcome messages
└── scripts/                # Helper scripts
    ├── apps.nix           # All flake apps
    └── dev-shell.nix      # Dev shell config
```

---

## 📁 `flake.nix` (Main - Clean & Thin)

```nix
{
  description = "NixOS MicroVM with VSCode + X11";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/7df7ff7d8e00218376575f0acdcc5d66741351ee";
    flake-utils.url = "github:numtide/flake-utils";
    microvm.url = "github:astro/microvm.nix";
    microvm.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, flake-utils, microvm }:
    let
      # Configuration constants
      customNixStore = "/home/reader/mynixroot/nix/store";
      workspaceSource = toString ./.;
      
      # Module arguments
      moduleArgs = {
        inherit customNixStore workspaceSource;
      };

    in {
      # NixOS MicroVM Configuration
      nixosConfigurations.my-microvm = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = moduleArgs;
        modules = [
          microvm.nixosModules.microvm
          ./modules/microvm-hardware.nix
          ./modules/networking.nix
          ./modules/users.nix
          ./modules/development.nix
          ./modules/shell-init.nix
        ];
      };
    } // flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
        
        ops = pkgs.callPackage ./package.nix { };
        
        # Import apps and dev shell
        apps = import ./scripts/apps.nix { 
          inherit pkgs self; 
        };
        
        devShell = import ./scripts/dev-shell.nix {
          inherit pkgs ops customNixStore;
        };

      in {
        packages = {
          default = ops;
          ops = ops;
          microvm = self.nixosConfigurations.my-microvm.config.microvm.declaredRunner;
        };

        apps = apps;
        
        devShells.default = devShell;
      }
    );
}
```

---

## 📁 `modules/microvm-hardware.nix`

```nix
{ config, lib, pkgs, customNixStore, workspaceSource, ... }:

{
  nixpkgs.config.allowUnfree = true;

  microvm = {
    hypervisor = "qemu";
    vcpu = 4;
    mem = 4096;
    
    interfaces = [{
      type = "user";
      id = "vm0";
      mac = "02:00:00:00:00:01";
    }];

    forwardPorts = [
      { from = "host"; host.port = 8083; guest.port = 8083; }
      { from = "host"; host.port = 2222; guest.port = 22; }
      { from = "host"; host.port = 3000; guest.port = 3000; }
    ];

    socket = "/tmp/nixos-microvm-control.socket";

    shares = [
      {
        source = customNixStore;
        mountPoint = "/nix/.ro-store";
        tag = "ro-store";
        proto = "9p";
        securityModel = "none";
      }
      {
        source = workspaceSource;
        mountPoint = "/workspace";
        tag = "workspace";
        proto = "9p";
        securityModel = "none";
      }
    ];
  };

  system.stateVersion = "25.05";
}
```

---

## 📁 `modules/networking.nix`

```nix
{ config, lib, pkgs, ... }:

{
  networking = {
    hostName = "nixos-dev";
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 8083 3000 ];
    };
  };

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "yes";
      X11Forwarding = true;
      X11UseLocalhost = true;
    };
  };
}
```

---

## 📁 `modules/users.nix`

```nix
{ config, lib, pkgs, ... }:

{
  # Enable sudo without password for wheel group
  security.sudo.wheelNeedsPassword = false;

  users.users.root = {
    password = "root";
  };
  
  users.users.dev = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    password = "dev";
    shell = pkgs.bash;
  };
}
```

---

## 📁 `modules/development.nix`

```nix
{ config, lib, pkgs, ... }:

{
  programs.git = {
    enable = true;
    config = {
      init.defaultBranch = "main";
      safe.directory = "/workspace";
    };
  };

  environment.systemPackages = with pkgs; [
    # Editors
    vim
    nano
    
    # Version control
    git
    
    # Development tools
    nodejs_22
    python3
    
    # GUI applications
    vscode
    
    # X11 utilities
    xorg.xauth
    xorg.xhost
    xorg.xeyes
    
    # Network tools
    curl
    wget
    netcat
    
    # System utilities
    htop
    tree
    file
    
    # VSCode wrapper for root
    (pkgs.writeScriptBin "vscode-root" ''
      #!/bin/sh
      exec ${pkgs.vscode}/bin/code --no-sandbox --user-data-dir=/root/.vscode-root "$@"
    '')
  ];

  # Shell aliases
  environment.shellAliases = {
    code-root = "code --no-sandbox --user-data-dir=/root/.vscode-root";
  };
}
```

---

## 📁 `modules/shell-init.nix`

```nix
{ config, lib, pkgs, ... }:

{
  environment.interactiveShellInit = ''
    if [ -n "$SSH_CONNECTION" ]; then
      echo "✅ Connected via SSH"
      echo "   User: $(whoami)"
      echo "   DISPLAY=$DISPLAY"
      echo ""
      if [ "$(whoami)" = "root" ]; then
        echo "Test X11:  xeyes &"
        echo "VSCode:    code-root /workspace"
        echo ""
        echo "💡 Tip: Login as 'dev' user for regular VSCode:"
        echo "   ssh -X dev@localhost -p 2222"
      else
        echo "Test X11:  xeyes &"
        echo "VSCode:    code /workspace"
      fi
    else
      echo "⚠️  Direct console - X11 won't work!"
      echo "   Use: ssh -X dev@localhost -p 2222"
    fi
  '';
}
```

---

## 📁 `scripts/apps.nix`

```nix
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
      echo "⚠️  Use 'code-root' command for VSCode as root"
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
```

---

## 📁 `scripts/dev-shell.nix`

```nix
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
    echo "   2. Terminal 2: ~/nixstatic run .#connect"
    echo ""
    echo "📋 Commands:"
    echo "   ~/nixstatic run .#microvm        - Start VM"
    echo "   ~/nixstatic run .#connect        - SSH as 'dev' (recommended)"
    echo "   ~/nixstatic run .#connect-root   - SSH as 'root'"
    echo "   ~/nixstatic run .#vscode         - VSCode as 'dev'"
    echo "   ~/nixstatic run .#vscode-root    - VSCode as root"
    echo "   ~/nixstatic run .#test-x11       - Test X11"
    echo ""
    echo "👤 Users:"
    echo "   dev  / dev   - Regular user (recommended for VSCode)"
    echo "   root / root  - Admin user (use 'code-root' for VSCode)"
    echo ""
    echo "💡 Inside VM:"
    echo "   code /workspace       - VSCode (as dev)"
    echo "   code-root /workspace  - VSCode (as root)"
  '';
}
```

---

## Create the Directory Structure

```bash
cd ~/develop/nixos-qemu

# Create directories
mkdir -p modules scripts

# Move/create module files
# (Copy the content above into each file)
```

---

## Update `.gitignore`

```bash
cat > .gitignore << 'EOF'
# MicroVM runtime
*.socket
/tmp/

# Ops/Nanos
.ops/
*.img

# Node.js
node_modules/

# Editor
.vscode/
*.swp
*~

# Build artifacts
result
result-*
EOF
```

---

## Benefits of This Structure

| Aspect | Before | After |
|--------|--------|-------|
| **File size** | 1 huge file (250+ lines) | Multiple small files (20-50 lines each) |
| **Maintainability** | Hard to find things | Logical separation by concern |
| **Reusability** | Monolithic | Modules can be reused |
| **Testing** | Must rebuild everything | Can test individual modules |
| **Collaboration** | Merge conflicts | Easier to work on separate parts |

---

## Usage (Same as Before)

```bash
# Everything works the same!
~/nixstatic run .#microvm
~/nixstatic run .#connect
~/nixstatic run .#vscode
```

---

## Optional: Add Module Documentation

Create `modules/README.md`:

```markdown
# NixOS MicroVM Modules

## Module Overview

- **microvm-hardware.nix** - VM resources, shares, ports
- **networking.nix** - Network config, SSH, firewall
- **users.nix** - User accounts and permissions
- **development.nix** - Dev tools, packages, VSCode
- **shell-init.nix** - Welcome messages and hints

## Customization

Edit any module to change configuration:

- Want more RAM? → `microvm-hardware.nix` (change `mem`)
- Add ports? → `microvm-hardware.nix` (add to `forwardPorts`)
- Add packages? → `development.nix` (add to `systemPackages`)
- Change users? → `users.nix`
```
