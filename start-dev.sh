#!/bin/bash

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

echo "╔════════════════════════════════════════╗"
echo "║  MicroVM Development Environment       ║"
echo "╚════════════════════════════════════════╝"
echo ""

# Function to check if VM is running
check_vm() {
  ssh -o ConnectTimeout=2 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null dev@localhost -p 2222 'exit' 2>/dev/null
}

# Check if VM is already running
if check_vm; then
  echo "✅ VM is already running"
  echo ""
else
  echo "🚀 Starting MicroVM..."
  echo "   This will open in a new terminal window"
  echo ""
  
  # Start VM in new terminal (if using GNOME Terminal, xterm, etc.)
  if command -v gnome-terminal &> /dev/null; then
    gnome-terminal --title="MicroVM" -- bash -c "cd $PROJECT_DIR && ~/nixstatic run .#microvm; read -p 'Press Enter to close...'"
  elif command -v xterm &> /dev/null; then
    xterm -title "MicroVM" -e "cd $PROJECT_DIR && ~/nixstatic run .#microvm; read -p 'Press Enter to close...'" &
  else
    echo "⚠️  Please start VM manually in another terminal:"
    echo "   ~/nixstatic run .#microvm"
    echo ""
    read -p "Press Enter when VM is running..."
  fi
  
  # Wait for VM to be ready
  echo "⏳ Waiting for VM to start..."
  for i in {1..30}; do
    if check_vm; then
      echo "✅ VM is ready!"
      sleep 2
      break
    fi
    sleep 1
    echo -n "."
  done
  echo ""
fi

# Launch VSCode
echo "🚀 Launching VSCode..."
echo ""
echo "📋 In VSCode, open terminals:"
echo "   1. Click '+' dropdown → 'Local Bash'"
echo "   2. Click '+' dropdown → 'VM (dev)'"
echo ""
echo "   Or use keybindings:"
echo "   - Ctrl+Shift+H = Local terminal"
echo "   - Ctrl+Shift+V = VM terminal"
echo ""

~/nixstatic run .#vscode
