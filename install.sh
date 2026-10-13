#!/usr/bin/env bash
# Install wsl2-ssh-agent from the signed apt repo and enable it for the current user.
# Safe to re-run. Usage:
#   curl -fsSL https://christianboehm.github.io/wsl2-ssh-agent-deb/install.sh | bash
set -euo pipefail

BASE=https://christianboehm.github.io/wsl2-ssh-agent-deb
KEYRING=/usr/share/keyrings/cboehm-archive-keyring.gpg
SOURCES=/etc/apt/sources.list.d/wsl2-ssh-agent.sources
FPR=0FBAC5753A1D3024F8F19F122FBF7F20A4DA842E

step() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m!! %s\033[0m\n' "$*"; }

if [ "$(id -u)" -eq 0 ]; then
  echo "Run as your normal user (sudo is used where needed)." >&2; exit 1
fi
grep -qi microsoft /proc/version || warn "This does not look like WSL — the package only makes sense inside WSL2."

# --- 1. Signing key (fingerprint pinned) ---
step "Repository signing key"
TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT
curl -fsSL "$BASE/KEY.asc" | gpg --dearmor > "$TMP"
if ! gpg --show-keys --with-colons "$TMP" | grep -q "^fpr:::::::::${FPR}:"; then
  echo "Downloaded key fingerprint does not match $FPR — aborting." >&2; exit 1
fi
sudo install -Dm644 "$TMP" "$KEYRING"
echo "Installed $KEYRING ($FPR)"

# --- 2. apt source ---
step "apt source"
sudo tee "$SOURCES" >/dev/null <<EOF
Types: deb
URIs: $BASE
Suites: stable
Components: main
Signed-By: $KEYRING
EOF
echo "Wrote $SOURCES"

# --- 3. Install ---
step "Install package"
sudo apt-get update -o Dir::Etc::sourcelist="$SOURCES" -o Dir::Etc::sourceparts=- -o APT::Get::List-Cleanup=0
sudo apt-get install -y wsl2-ssh-agent

# --- 4. User service ---
step "Enable user service"
systemctl --user daemon-reload
systemctl --user enable --now wsl2-ssh-agent
sleep 1
systemctl --user --no-pager status wsl2-ssh-agent | head -5 || true

# --- 5. Windows side checks ---
step "Windows checks"
if command -v sc.exe >/dev/null; then
  if sc.exe query ssh-agent 2>/dev/null | grep -q RUNNING; then
    warn "Windows service 'OpenSSH Authentication Agent' is RUNNING."
    warn "If you use 1Password's SSH agent, stop + disable it (services.msc), it claims the same pipe."
  else
    echo "Windows 'OpenSSH Authentication Agent' not running — OK for 1Password."
  fi
fi

# --- 6. Test ---
step "Test"
export SSH_AUTH_SOCK="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/wsl2-ssh-agent.sock"
if timeout 20 ssh-add -l; then
  echo "Agent reachable."
else
  warn "ssh-add -l failed. In 1Password: Settings → Developer → 'Use the SSH agent' must be on."
fi
echo
echo "Open a new shell — SSH_AUTH_SOCK is set by /etc/profile.d/wsl2-ssh-agent.sh."
