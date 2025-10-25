{
  lib,
  buildGoModule,
  fetchFromGitHub,
  protobuf,
  protoc-gen-go,
  protoc-gen-go-grpc,
  grpc-gateway,
  buf,
  gnumake,
  writeScriptBin,
}:

let
  opsSetup = writeScriptBin "ops-setup" ''
    #!/bin/sh
    set -e
    
    echo "🔧 Setting up Ops environment..."
    
    OPS_DIR="''${OPS_DIR:-$HOME/.ops}"
    
    # Check if already set up
    if [ -f "$OPS_DIR/0.1.54/kernel.img" ]; then
      echo "✅ Nanos kernel 0.1.54 already installed!"
      echo ""
      echo "Kernel location: $OPS_DIR/0.1.54/"
      echo ""
      echo "You're ready to run:"
      echo "  run-local-vm"
      exit 0
    fi
    
    echo "📦 Downloading Nanos kernel 0.1.54..."
    echo ""
    
    # The 'ops update' command will show a permission error when trying to 
    # update its own binary in /nix/store (which is read-only), but it will
    # still successfully download the kernel files. We ignore the error.
    ops update 0.1.54 2>&1 | grep -v "Failed to update" | grep -v "permission denied" || true
    
    if [ -f "$OPS_DIR/0.1.54/kernel.img" ]; then
      echo ""
      echo "✅ Setup complete!"
      echo ""
      echo "Kernel installed in: $OPS_DIR/0.1.54/"
      echo ""
      echo "You're ready to run:"
      echo "  run-local-vm"
    else
      echo ""
      echo "⚠️  Kernel download may have failed."
      echo "Try running manually: ops update 0.1.54"
      exit 1
    fi
  '';

in buildGoModule rec {
  pname = "ops";
  version = "unstable-2025-10-05";

  src = fetchFromGitHub {
    owner = "nanovms";
    repo = "ops";
    rev = "36fcd46119fd5b3cc7c5a9128758927b58ddc9b7";
    sha256 = "sha256-8VRdeuXCkxo+0PioYb1pUsFBE+e+TgNIKD5t7vgmEmQ=";
  };

  proxyVendor = true;
  vendorHash = "sha256-M+2k7K4HDRP0Qo78t9H1Pg1XkIqrjjNAOTgF1kXJmMk=";

  nativeBuildInputs = [
    protobuf
    protoc-gen-go
    protoc-gen-go-grpc
    grpc-gateway
    buf
    gnumake
  ];

  env.GOWORK = "off";

  preBuild = ''
    echo "Running 'make generate' to create Protocol Buffer code..."
    make generate
  '';

  subPackages = [ "." ];

  ldflags = [
    "-s"
    "-w"
    "-X github.com/nanovms/ops/lepton.Version=${version}"
  ];

  tags = [
    "aws" "azure" "do" "gcp" "hyperv" "ibm" "linode" "oci"
    "openshift" "openstack" "proxmox" "upcloud" "vbox" "vsphere" "vultr"
  ];

  doCheck = false;

  # Install setup script alongside ops
  postInstall = ''
    cp ${opsSetup}/bin/ops-setup $out/bin/
  '';

  meta = with lib; {
    description = "Build and run nanos unikernels";
    homepage = "https://github.com/nanovms/ops";
    license = licenses.mit;
    platforms = platforms.linux;
    mainProgram = "ops";
  };
}