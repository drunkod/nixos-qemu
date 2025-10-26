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
