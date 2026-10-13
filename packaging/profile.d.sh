# Use the wsl2-ssh-agent socket if the user service is running.
if [ -n "${XDG_RUNTIME_DIR:-}" ] && [ -S "$XDG_RUNTIME_DIR/wsl2-ssh-agent.sock" ]; then
    export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/wsl2-ssh-agent.sock"
fi
