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
workspaceSource = "/home/reader/develop/nixos-qemu";

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
# ./modules/networking-profiles.nix
./modules/users.nix
./modules/development.nix
./modules/shell-init.nix
./modules/nix-config.nix
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
