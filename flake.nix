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
      customNixStore = "/home/reader/mynixroot/nix/store";
      workspaceSource = toString ./.;
      
      microVMConfig = { config, lib, pkgs, ... }: {
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

        programs.git = {
          enable = true;
          config = {
            init.defaultBranch = "main";
            safe.directory = "/workspace";
          };
        };

        # Enable sudo without password for dev user
        security.sudo.wheelNeedsPassword = false;

        users.users.root.password = "root";
        
        users.users.dev = {
          isNormalUser = true;
          extraGroups = [ "wheel" ];
          password = "dev";
          shell = pkgs.bash;
        };

        # Development packages
        environment.systemPackages = with pkgs; [
          vim
          nano
          git
          nodejs_22
          python3
          vscode
          xorg.xauth
          xorg.xhost
          xorg.xeyes
          curl
          wget
          netcat
          htop
          tree
          file
          
          # Create VSCode wrapper for root
          (pkgs.writeScriptBin "vscode-root" ''
            #!/bin/sh
            exec ${pkgs.vscode}/bin/code --no-sandbox --user-data-dir=/root/.vscode-root "$@"
          '')
        ];

        # Alias for easier VSCode usage
        environment.shellAliases = {
          code-root = "code --no-sandbox --user-data-dir=/root/.vscode-root";
        };

        # Helper script for X11 info
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

        system.stateVersion = "25.05";
      };

    in {
      nixosConfigurations.my-microvm = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          microvm.nixosModules.microvm
          microVMConfig
        ];
      };
    } // flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
        
        ops = pkgs.callPackage ./package.nix { };

      in {
        packages = {
          default = ops;
          ops = ops;
          microvm = self.nixosConfigurations.my-microvm.config.microvm.declaredRunner;
        };

        apps = {
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

          # Launch VSCode as root (with --no-sandbox)
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
        };

        devShells.default = pkgs.mkShell {
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
        };
      }
    );
}