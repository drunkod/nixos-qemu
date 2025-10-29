# 🌍 Global VSCode Setup for VM Development

Setup VSCode **once** globally, works for **all** your GitHub projects automatically!

## 📝 Global VSCode Configuration

### Step 1: Edit Global VSCode Settings

Edit **`~/.config/Code/User/settings.json`** (or on macOS: `~/Library/Application Support/Code/User/settings.json`)

```json
{
  "terminal.integrated.profiles.linux": {
    "Local Bash": {
      "path": "/bin/bash",
      "icon": "terminal-bash",
      "color": "terminal.ansiGreen"
    },
    "VM (dev) - Auto": {
      "path": "/bin/bash",
      "args": [
        "-c",
        "PROJECT_NAME=$(basename \"${PWD}\"); ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -t dev@localhost -p 2222 \"cd /workspace/$PROJECT_NAME 2>/dev/null || cd /workspace; exec bash\""
      ],
      "icon": "vm",
      "color": "terminal.ansiBlue"
    },
    "VM (root) - Auto": {
      "path": "/bin/bash",
      "args": [
        "-c",
        "PROJECT_NAME=$(basename \"${PWD}\"); ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -t root@localhost -p 2222 \"cd /workspace/$PROJECT_NAME 2>/dev/null || cd /workspace; exec bash\""
      ],
      "icon": "shield",
      "color": "terminal.ansiRed"
    },
    "VM (dev) - Projects Root": {
      "path": "/bin/bash",
      "args": [
        "-c",
        "echo '🔌 Connecting to VM /workspace...'; ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -t dev@localhost -p 2222 'cd /workspace && exec bash'"
      ],
      "icon": "folder",
      "color": "terminal.ansiCyan"
    }
  },
  
  "terminal.integrated.defaultProfile.linux": "Local Bash",
  
  // Font settings
  "editor.fontFamily": "'JetBrains Mono', 'Fira Code', 'Cascadia Code', monospace",
  "editor.fontSize": 14,
  "editor.fontLigatures": true,
  "terminal.integrated.fontFamily": "'JetBrains Mono', 'Fira Code', monospace",
  "terminal.integrated.fontSize": 13,
  "terminal.integrated.lineHeight": 1.2,
  
  // Auto-save
  "files.autoSave": "afterDelay",
  "files.autoSaveDelay": 1000,
  
  // File watcher exclusions
  "files.watcherExclude": {
    "**/.git/objects/**": true,
    "**/.git/subtree-cache/**": true,
    "**/node_modules/**": true,
    "**/.web/**": true,
    "**/venv/**": true,
    "**/__pycache__/**": true,
    "**/.ops/**": true,
    "**/*.socket": true
  },
  
  // Python settings (global defaults)
  "python.defaultInterpreterPath": "${workspaceFolder}/venv/bin/python",
  "python.terminal.activateEnvironment": false,
  "python.analysis.autoImportCompletions": true,
  
  // Git
  "git.autofetch": true,
  "git.confirmSync": false,
  
  // Editor
  "editor.formatOnSave": true,
  "editor.rulers": [80, 120],
  "editor.minimap.enabled": false,
  
  // Terminal
  "terminal.integrated.cursorBlinking": true,
  "terminal.integrated.cursorStyle": "line"
}
```

### Step 2: Create SSH Config (No Password!)

Edit **`~/.ssh/config`**:

```ssh-config
# MicroVM Development Environment
Host microvm vm devvm
    HostName localhost
    Port 2222
    User dev
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    LogLevel ERROR
    ForwardX11 yes
    ForwardX11Trusted yes
    
Host microvm-root vm-root
    HostName localhost
    Port 2222
    User root
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    LogLevel ERROR
    ForwardX11 yes
    ForwardX11Trusted yes
```

**Now you can connect easily:**
```bash
ssh microvm        # Connects as dev user
ssh microvm-root   # Connects as root
```

### Step 3: Generate SSH Key (One-time)

```bash
# Generate key
ssh-keygen -t ed25519 -f ~/.ssh/microvm_key -N ""

# Add to SSH config
cat >> ~/.ssh/config << 'EOF'

# Use the key for microvm
Host microvm vm devvm microvm-root vm-root
    IdentityFile ~/.ssh/microvm_key
EOF
```

**Copy key to VM:**
```bash
# Start VM first
cd "🔧 MicroVM Config"
~/nixstatic run .#microvm

# In another terminal, copy key
ssh-copy-id -i ~/.ssh/microvm_key.pub -p 2222 dev@localhost
# Enter password: dev (last time!)

ssh-copy-id -i ~/.ssh/microvm_key.pub -p 2222 root@localhost
# Enter password: root (last time!)
```

**Now SSH is password-free!** ✨

## 🚀 How It Works

### Terminal Profile: "VM (dev) - Auto"

This profile **automatically detects** your current project folder and opens it in the VM!

**Example:**
- Open VSCode in: `📁 Projects/Simple-Jazz-Reflex-Starter-Template/`
- Open terminal → Connects to: `/workspace/Simple-Jazz-Reflex-Starter-Template/`

**Magic!** 🎩✨

### How the Auto-Detection Works

```bash
PROJECT_NAME=$(basename "${PWD}")  # Gets "Simple-Jazz-Reflex-Starter-Template"
cd /workspace/$PROJECT_NAME        # Goes to /workspace/Simple-Jazz-Reflex-Starter-Template
```

## 📋 Create Global Helper Scripts

Create **`~/bin/vm-helpers.sh`**:

```bash
#!/bin/bash

# VM Development Helper Functions
# Source this in your ~/.bashrc: source ~/bin/vm-helpers.sh

# Quick connect to VM in current project
vm() {
    local project_name=$(basename "$PWD")
    echo "🔌 Connecting to VM: /workspace/$project_name"
    ssh -t microvm "cd /workspace/$project_name 2>/dev/null || cd /workspace; exec bash"
}

# Connect to VM as root
vmroot() {
    local project_name=$(basename "$PWD")
    echo "🔌 Connecting to VM as root: /workspace/$project_name"
    ssh -t microvm-root "cd /workspace/$project_name 2>/dev/null || cd /workspace; exec bash"
}

# Start the VM
vm-start() {
    echo "🚀 Starting MicroVM..."
    cd "$HOME/🔧 MicroVM Config" || cd "$HOME/MicroVM Config" || {
        echo "❌ MicroVM Config folder not found"
        return 1
    }
    ~/nixstatic run .#microvm
}

# Check if VM is running
vm-check() {
    if ssh -q -o ConnectTimeout=2 microvm exit 2>/dev/null; then
        echo "✅ VM is running"
        return 0
    else
        echo "❌ VM is not running"
        echo "💡 Start with: vm-start"
        return 1
    fi
}

# Open VSCode with VM terminal
vm-code() {
    local project_dir="${1:-.}"
    echo "🚀 Opening VSCode: $project_dir"
    code "$project_dir"
}

# Run command in VM from current project
vm-run() {
    local project_name=$(basename "$PWD")
    echo "🏃 Running in VM: $@"
    ssh -t microvm "cd /workspace/$project_name && $@"
}

# Enter nix develop in VM
vm-nix() {
    local project_name=$(basename "$PWD")
    echo "❄️  Entering nix develop in VM..."
    ssh -t microvm "cd /workspace/$project_name && nix develop"
}

# Quick help
vm-help() {
    cat << 'EOF'
🔧 VM Helper Commands:

  vm              - Connect to VM (auto-detects current project)
  vmroot          - Connect to VM as root
  vm-start        - Start the MicroVM
  vm-check        - Check if VM is running
  vm-code [dir]   - Open VSCode in directory
  vm-run <cmd>    - Run command in VM current project
  vm-nix          - Enter nix develop in VM
  vm-help         - Show this help

Examples:
  vm                          # Connect to current project in VM
  vm-run "make test"          # Run tests in VM
  vm-run "nix develop"        # Enter nix shell
  vm-nix                      # Same as above
EOF
}
```

Make it executable:
```bash
mkdir -p ~/bin
chmod +x ~/bin/vm-helpers.sh
```

Add to **`~/.bashrc`**:
```bash
# VM Development Helpers
if [ -f ~/bin/vm-helpers.sh ]; then
    source ~/bin/vm-helpers.sh
fi
```

Reload:
```bash
source ~/.bashrc
```

## 🎯 Usage Examples

### Example 1: Clone and Work on Any Project

```bash
# Clone any GitHub project
cd ~/Projects
git clone https://github.com/username/my-new-project
cd my-new-project

# Start VM (if not running)
vm-check || vm-start &

# Open in VSCode
code .

# In VSCode terminal:
# Click dropdown → "VM (dev) - Auto"
# Automatically opens at /workspace/my-new-project!

# Or from command line:
vm
# Already in /workspace/my-new-project!
```

### Example 2: Work on Jazz-Reflex Template

```bash
cd "📁 Projects/Simple-Jazz-Reflex-Starter-Template"

# Check VM
vm-check

# Connect to VM (auto goes to project folder)
vm

# Or run commands directly
vm-run "nix develop"
vm-run "make install"
vm-run "make run"
```

### Example 3: Multiple Projects Same VM

```bash
# Project 1
cd ~/Projects/jazz-app
vm-run "reflex run --port 3000" &

# Project 2
cd ~/Projects/another-app
vm-run "reflex run --port 3001" &

# Both running in same VM!
# Access from host:
# http://localhost:3000
# http://localhost:3001
```

## 🎨 Global VSCode Keyboard Shortcuts

Edit **`~/.config/Code/User/keybindings.json`**:

```json
[
  {
    "key": "ctrl+alt+v",
    "command": "workbench.action.terminal.new",
    "args": {
      "profileName": "VM (dev) - Auto"
    }
  },
  {
    "key": "ctrl+alt+r",
    "command": "workbench.action.terminal.new",
    "args": {
      "profileName": "VM (root) - Auto"
    }
  },
  {
    "key": "ctrl+alt+l",
    "command": "workbench.action.terminal.new",
    "args": {
      "profileName": "Local Bash"
    }
  },
  {
    "key": "ctrl+alt+w",
    "command": "workbench.action.terminal.new",
    "args": {
      "profileName": "VM (dev) - Projects Root"
    }
  }
]
```

**Now use keyboard shortcuts:**
- **Ctrl+Alt+V** - New VM (dev) terminal
- **Ctrl+Alt+R** - New VM (root) terminal  
- **Ctrl+Alt+L** - New local terminal
- **Ctrl+Alt+W** - VM at /workspace root

## 📦 Create a Startup Script

**`~/bin/dev-start.sh`**:

```bash
#!/bin/bash

echo "🚀 Starting Development Environment"
echo ""

# Check if VM is running
if ssh -q -o ConnectTimeout=2 microvm exit 2>/dev/null; then
    echo "✅ VM already running"
else
    echo "🔄 Starting VM..."
    cd "$HOME/🔧 MicroVM Config" || cd "$HOME/MicroVM-Config" || {
        echo "❌ Cannot find MicroVM Config folder"
        exit 1
    }
    
    # Start VM in background
    gnome-terminal --title="MicroVM" -- bash -c "~/nixstatic run .#microvm; read -p 'Press Enter to close...'" 2>/dev/null || \
    xterm -title "MicroVM" -e "~/nixstatic run .#microvm; read -p 'Press Enter to close...'" 2>/dev/null || \
    {
        echo "⚠️  Please start VM manually:"
        echo "   cd '🔧 MicroVM Config' && ~/nixstatic run .#microvm"
        exit 1
    }
    
    # Wait for VM
    echo "⏳ Waiting for VM to start..."
    for i in {1..30}; do
        if ssh -q -o ConnectTimeout=2 microvm exit 2>/dev/null; then
            echo "✅ VM is ready!"
            break
        fi
        sleep 1
        echo -n "."
    done
    echo ""
fi

# Open VSCode in current directory
if [ -n "$1" ]; then
    PROJECT_DIR="$1"
else
    PROJECT_DIR="."
fi

echo "🎨 Opening VSCode: $PROJECT_DIR"
code "$PROJECT_DIR"

echo ""
echo "✅ Development environment ready!"
echo ""
echo "💡 In VSCode terminal, select: 'VM (dev) - Auto'"
echo "   Or press: Ctrl+Alt+V"
```

Make it executable:
```bash
chmod +x ~/bin/dev-start.sh
```

**Add to PATH** (add to `~/.bashrc`):
```bash
export PATH="$HOME/bin:$PATH"
```

## 🎯 Complete Workflow (Global Setup)

### One-Time Setup (Do Once)

```bash
# 1. Setup SSH config
cat >> ~/.ssh/config << 'EOF'

Host microvm vm devvm
    HostName localhost
    Port 2222
    User dev
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    LogLevel ERROR
    
Host microvm-root
    HostName localhost
    Port 2222
    User root
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    LogLevel ERROR
EOF

# 2. Generate SSH key
ssh-keygen -t ed25519 -f ~/.ssh/microvm_key -N ""
echo "    IdentityFile ~/.ssh/microvm_key" >> ~/.ssh/config

# 3. Start VM
cd "🔧 MicroVM Config"
~/nixstatic run .#microvm &

# Wait a moment, then copy keys
sleep 10
ssh-copy-id -i ~/.ssh/microvm_key.pub -p 2222 dev@localhost
ssh-copy-id -i ~/.ssh/microvm_key.pub -p 2222 root@localhost

# 4. Setup helper scripts
mkdir -p ~/bin
# Copy vm-helpers.sh content to ~/bin/vm-helpers.sh
# Copy dev-start.sh content to ~/bin/dev-start.sh
chmod +x ~/bin/*.sh

# 5. Add to bashrc
echo "source ~/bin/vm-helpers.sh" >> ~/.bashrc
echo "export PATH=\"\$HOME/bin:\$PATH\"" >> ~/.bashrc
source ~/.bashrc

# 6. Configure VSCode (copy settings above)
```

### Daily Workflow (Any Project)

```bash
# Option 1: Auto-start everything
dev-start.sh ~/Projects/my-project

# Option 2: Manual
cd ~/Projects/my-project
vm-check || vm-start &
code .
# Press Ctrl+Alt+V for VM terminal

# Option 3: CLI only
cd ~/Projects/my-project
vm
nix develop
make run
```

## 🎉 Benefits of Global Setup

✅ **No per-project configuration** - Works with any GitHub repo  
✅ **Auto-detects project** - Terminal opens in correct folder  
✅ **Password-free SSH** - No typing passwords  
✅ **Keyboard shortcuts** - Fast terminal access  
✅ **Helper commands** - `vm`, `vm-run`, `vm-nix`  
✅ **Works everywhere** - Same setup for all projects  

## 📝 Quick Reference Card

Create **`~/VM-COMMANDS.md`**:

```markdown
# VM Development Quick Reference

## Terminal Profiles (Ctrl+` then dropdown)
- **VM (dev) - Auto** - Auto-connects to current project
- **VM (root) - Auto** - Same, but as root
- **VM (dev) - Projects Root** - Opens at /workspace
- **Local Bash** - Host machine

## Keyboard Shortcuts
- **Ctrl+Alt+V** - New VM (dev) terminal
- **Ctrl+Alt+R** - New VM (root) terminal
- **Ctrl+Alt+L** - New local terminal
- **Ctrl+Alt+W** - VM /workspace terminal

## CLI Commands
```bash
vm              # Connect to VM (current project)
vmroot          # Connect as root
vm-start        # Start the VM
vm-check        # Check if running
vm-run "cmd"    # Run command in VM
vm-nix          # Enter nix develop
vm-help         # Show help
```

## SSH Shortcuts
```bash
ssh microvm      # Connect as dev
ssh microvm-root # Connect as root
```

## Quick Start Any Project
```bash
cd ~/Projects/any-project
dev-start.sh
# VSCode opens, press Ctrl+Alt+V for VM terminal
```
```
