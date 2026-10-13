# wsl2-ssh-agent — Debian / Ubuntu packages

[![release](https://github.com/ChristianBoehm/wsl2-ssh-agent-deb/actions/workflows/release.yml/badge.svg)](https://github.com/ChristianBoehm/wsl2-ssh-agent-deb/actions/workflows/release.yml)
[![latest](https://img.shields.io/github/v/release/ChristianBoehm/wsl2-ssh-agent-deb)](https://github.com/ChristianBoehm/wsl2-ssh-agent-deb/releases/latest)
[![license](https://img.shields.io/github/license/ChristianBoehm/wsl2-ssh-agent-deb)](LICENSE)

Use your **Windows SSH agent** — e.g. **1Password** — from `ssh` and `git` inside **WSL2**.

This repo publishes a signed apt repository with `.deb` packages of
[mame/wsl2-ssh-agent](https://github.com/mame/wsl2-ssh-agent). New upstream releases are
packaged automatically.

```
ssh / git (WSL2) ──► wsl2-ssh-agent.sock ──► PowerShell.exe ──► \\.\pipe\openssh-ssh-agent ──► 1Password / ssh-agent.exe
```

## Quick start

```bash
curl -fsSL https://christianboehm.github.io/wsl2-ssh-agent-deb/install.sh | bash
```

Then open a new terminal and check:

```bash
ssh-add -l               # lists the keys from your Windows agent
ssh -T git@github.com    # "Hi <user>! You've successfully authenticated…"
```

## Requirements

**WSL2** with systemd (default on current Ubuntu/Debian WSL images), amd64 or arm64.

**Windows**, one of:

- **1Password** — *Settings → Developer → Use the SSH agent*. Stop and disable the Windows service
  *OpenSSH Authentication Agent*, otherwise it occupies the same pipe.
- **Windows OpenSSH agent** — service *OpenSSH Authentication Agent* running.

## What the installer does

1. Downloads the repository key and checks its fingerprint
2. Adds the apt source `/etc/apt/sources.list.d/wsl2-ssh-agent.sources`
3. Installs `wsl2-ssh-agent` and enables the systemd user service
4. Warns if the Windows OpenSSH agent would conflict with 1Password, then tests `ssh-add -l`

<details>
<summary>Manual installation</summary>

```bash
curl -fsSL https://christianboehm.github.io/wsl2-ssh-agent-deb/KEY.asc \
  | sudo gpg --dearmor -o /usr/share/keyrings/cboehm-archive-keyring.gpg

sudo tee /etc/apt/sources.list.d/wsl2-ssh-agent.sources >/dev/null <<'EOF'
Types: deb
URIs: https://christianboehm.github.io/wsl2-ssh-agent-deb
Suites: stable
Components: main
Signed-By: /usr/share/keyrings/cboehm-archive-keyring.gpg
EOF

sudo apt update && sudo apt install wsl2-ssh-agent
systemctl --user enable --now wsl2-ssh-agent
```

</details>

## Update & uninstall

```bash
sudo apt update && sudo apt upgrade        # updates come through apt

systemctl --user disable --now wsl2-ssh-agent
sudo apt remove wsl2-ssh-agent
sudo rm /etc/apt/sources.list.d/wsl2-ssh-agent.sources /usr/share/keyrings/cboehm-archive-keyring.gpg
```

## Package contents

| Path | Purpose |
|---|---|
| `/usr/bin/wsl2-ssh-agent` | upstream binary, SHA-256 verified against upstream `checksums.txt` |
| `/usr/lib/systemd/user/wsl2-ssh-agent.service` | upstream user unit, socket at `$XDG_RUNTIME_DIR/wsl2-ssh-agent.sock` |
| `/etc/profile.d/wsl2-ssh-agent.sh` | sets `SSH_AUTH_SOCK` when the socket exists |

## Troubleshooting

| Symptom | Fix |
|---|---|
| `SSH_AUTH_SOCK` empty | open a new terminal, or `source /etc/profile.d/wsl2-ssh-agent.sh` |
| `ssh-add -l`: *communication with agent failed* | check `systemctl --user status wsl2-ssh-agent`; enable the 1Password SSH agent |
| keys from the wrong agent | stop/disable the Windows *OpenSSH Authentication Agent* service |

## Repository signing key

[`KEY.asc`](KEY.asc) — OpenPGP Ed25519, signs the repository `Release` files.

```
C07B F7B1 982F F6CC 6C54  4DF9 E780 6B47 427C 8FE8
```

## Building locally

```bash
./build-deb.sh 0.9.7 amd64      # → dist/wsl2-ssh-agent_0.9.7-1_amd64.deb
```

## License

Packaging scripts: [MIT](LICENSE) © Christian Boehm.
`wsl2-ssh-agent` itself: [MIT](https://github.com/mame/wsl2-ssh-agent/blob/master/LICENSE) © Yusuke Endoh —
this project is not affiliated with upstream.
