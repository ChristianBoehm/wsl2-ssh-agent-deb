# wsl2-ssh-agent for Debian / Ubuntu

Signed apt repository with `.deb` packages of [mame/wsl2-ssh-agent](https://github.com/mame/wsl2-ssh-agent)
(MIT, © Yusuke Endoh). The packages contain the unmodified upstream release binaries
(checksums verified against upstream `checksums.txt`) plus the upstream systemd user unit.

A GitHub Action checks upstream daily and publishes new versions automatically.

## Install

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

Open a new shell: `/etc/profile.d/wsl2-ssh-agent.sh` sets `SSH_AUTH_SOCK` when the socket exists.
Check with `ssh-add -l`.

## Windows prerequisites

- An agent serving the `\\.\pipe\openssh-ssh-agent` pipe:
  - **1Password:** Settings → Developer → *Use the SSH agent*, and stop/disable the Windows
    service *OpenSSH Authentication Agent* (it would claim the same pipe), or
  - the Windows *OpenSSH Authentication Agent* service itself.

## Package contents

| Path | |
|---|---|
| `/usr/bin/wsl2-ssh-agent` | upstream binary |
| `/usr/lib/systemd/user/wsl2-ssh-agent.service` | upstream user unit, socket `$XDG_RUNTIME_DIR/wsl2-ssh-agent.sock` |
| `/etc/profile.d/wsl2-ssh-agent.sh` | exports `SSH_AUTH_SOCK` |

## Build locally

```bash
./build-deb.sh 0.9.7 amd64      # → dist/wsl2-ssh-agent_0.9.7-1_amd64.deb
```

## Signing key

`KEY.asc` — OpenPGP Ed25519 key used to sign the repository `Release` files.

Fingerprint: `0FBA C575 3A1D 3024 F8F1  9F12 2FBF 7F20 A4DA 842E`
