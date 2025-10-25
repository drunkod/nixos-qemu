{
  description = "NixOS MicroVM in QEMU - Custom Static Nix Edition";

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
        microvm = {
          hypervisor = "qemu";
          
          vcpu = 2;
          mem = 1024;
          
          interfaces = [{
            type = "user";
            id = "vm0";
            mac = "02:00:00:00:00:01";
          }];

          # Use built-in port forwarding
          forwardPorts = [
            { from = "host"; host.port = 8083; guest.port = 8083; }
            { from = "host"; host.port = 2222; guest.port = 22; }
          ];

          socket = "/tmp/nixos-microvm-control.socket";

          # Let microvm.nix handle shares properly
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
          hostName = "nixos-microvm";
          firewall.allowedTCPPorts = [ 22 8083 ];
        };

        services.openssh = {
          enable = true;
          settings.PermitRootLogin = "yes";
        };

        systemd.services.webapp = {
          wantedBy = [ "multi-user.target" ];
          after = [ "network.target" ];
          serviceConfig = {
            Type = "simple";
            Restart = "always";
          };
          script = ''
            cd /workspace
            ${pkgs.nodejs}/bin/node hi.js
          '';
        };

        users.users.root.password = "root";
        
        users.users.dev = {
          isNormalUser = true;
          extraGroups = [ "wheel" ];
          password = "dev";
        };

        environment.systemPackages = with pkgs; [
          vim
          curl
          htop
          nodejs
        ];

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

      in
      {
        packages = {
          default = ops;
          ops = ops;
          microvm = self.nixosConfigurations.my-microvm.config.microvm.declaredRunner;
        };

        apps = {
          default = {
            type = "app";
            program = "${ops}/bin/ops";
          };

          microvm = {
            type = "app";
            program = "${self.nixosConfigurations.my-microvm.config.microvm.declaredRunner}/bin/microvm-run";
          };

          test-qemu = {
            type = "app";
            program = toString (pkgs.writeShellScript "test-qemu" ''
              echo "🧪 Testing QEMU + Custom Nix Store..."
              echo ""
              echo "QEMU version:"
              ${pkgs.qemu}/bin/qemu-system-x86_64 --version
              echo ""
              echo "Custom Nix store: ${customNixStore}"
              echo "Project location: ${workspaceSource}"
              echo ""
              if [ -d "${customNixStore}" ]; then
                echo "✅ Custom Nix store exists"
                echo "   Items: $(ls ${customNixStore} 2>/dev/null | wc -l)"
              else
                echo "❌ Custom Nix store NOT FOUND!"
              fi
            '');
          };
        };

        devShells.default = pkgs.mkShell {
          buildInputs = [
            ops
            pkgs.qemu
            pkgs.nodejs
          ];
          
          shellHook = ''
            echo "╔════════════════════════════════════════╗"
            echo "║  NixOS MicroVM + Static Nix            ║"
            echo "╚════════════════════════════════════════╝"
            echo ""
            echo "🔧 Custom Static Nix Setup"
            echo "   Store: ${customNixStore}"
            echo "   Using: 9p filesystem (no root needed)"
            echo ""
            
            if [ ! -d "${customNixStore}" ]; then
              echo "⚠️  WARNING: Custom Nix store not found!"
              echo "   Expected: ${customNixStore}"
              exit 1
            fi
            
            if [ -f "$HOME/.ops/0.1.54/kernel.img" ] || [ -f "$HOME/.ops/nightly/kernel.img" ]; then
              echo "✅ Nanos kernel already installed"
            else
              echo "⚠️  Ops first time setup required!"
              echo "   Run: ops update 0.1.54"
            fi
            
            echo ""
            echo "Available commands:"
            echo "  🔷 MicroVM:"
            echo "    ~/nixstatic run .#microvm        - Run NixOS MicroVM"
            echo "    ~/nixstatic run .#test-qemu      - Test setup"
            echo ""
            echo "  🔶 Test App:"
            echo "    curl http://localhost:8083       - Test webapp"
            echo "    ssh root@localhost -p 2222       - SSH into VM (pw: root)"
            echo ""
            echo "⚠️  Using custom Nix store with 9p shares (non-root)"
          '';
        };
      }
    );
}