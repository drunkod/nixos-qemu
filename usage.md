
## Now Test

```bash
cd ~/develop/nixos-qemu


systemctl --user start microvm-virtiofsd-workspace.service
systemctl --user status microvm-virtiofsd-workspace.service
systemctl --user stop microvm-virtiofsd-workspace.service


# Terminal 1: Start VM
~/nixstatic run .#microvm

# Terminal 2: Launch VSCode (will wait until you close VSCode)
~/nixstatic run .#vscode
```

**How it works now:**

1. VSCode launches with `--wait` flag
2. SSH stays connected until you close VSCode
3. X11 tunnel remains active
4. No more white screen! ✨

## Alternative Usage

If you prefer VSCode in background and manual SSH control:

```bash
# Option 1: Use vscode-bg (Ctrl+C to stop)
~/nixstatic run .#vscode-bg

# Option 2: Interactive shell with VSCode
~/nixstatic run .#connect
# Then inside VM:
code /workspace &
# Keep terminal open, or VSCode will close
```

## Best Practice: Screen/Tmux

For production use, consider using `screen` or `tmux` in the VM:

```bash
# SSH to VM
~/nixstatic run .#connect

# Inside VM: start tmux
tmux

# Launch VSCode
code /workspace &

# Detach: Ctrl+B then D
# Now you can close SSH, VSCode keeps running!

# Reconnect later:
tmux attach
```
