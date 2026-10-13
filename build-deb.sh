#!/usr/bin/env bash
# Build a .deb of mame/wsl2-ssh-agent from the upstream release binary.
# Usage: ./build-deb.sh <version> <amd64|arm64> [revision]   e.g. ./build-deb.sh 0.9.7 amd64
set -euo pipefail

VERSION="${1:?version, e.g. 0.9.7}"
ARCH="${2:?arch: amd64 or arm64}"
REVISION="${3:-1}"
UPSTREAM="https://github.com/mame/wsl2-ssh-agent"
RAW="https://raw.githubusercontent.com/mame/wsl2-ssh-agent/v${VERSION}"

case "$ARCH" in
  amd64) ASSET="wsl2-ssh-agent" ;;
  arm64) ASSET="wsl2-ssh-agent-arm64" ;;
  *) echo "unsupported arch: $ARCH" >&2; exit 1 ;;
esac

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${OUT_DIR:-$HERE/dist}"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# --- 1. Download + verify upstream binary ---
cd "$WORK"
curl -fsSL -o "$ASSET"        "$UPSTREAM/releases/download/v${VERSION}/${ASSET}"
curl -fsSL -o checksums.txt   "$UPSTREAM/releases/download/v${VERSION}/checksums.txt"
grep -E "  ${ASSET}\$" checksums.txt | sha256sum -c -
curl -fsSL -o wsl2-ssh-agent.service "$RAW/extras/systemd/user/wsl2-ssh-agent.service"

# --- 2. Stage package tree ---
PKG="$WORK/pkg"
install -Dm755 "$ASSET"                       "$PKG/usr/bin/wsl2-ssh-agent"
install -Dm644 wsl2-ssh-agent.service         "$PKG/usr/lib/systemd/user/wsl2-ssh-agent.service"
install -Dm644 "$HERE/packaging/profile.d.sh" "$PKG/etc/profile.d/wsl2-ssh-agent.sh"
install -Dm644 "$HERE/packaging/copyright"    "$PKG/usr/share/doc/wsl2-ssh-agent/copyright"

# --- 3. Control files ---
install -d "$PKG/DEBIAN"
SIZE="$(du -sk --exclude=DEBIAN "$PKG" | cut -f1)"
sed -e "s/@VERSION@/${VERSION}-${REVISION}/" \
    -e "s/@ARCH@/${ARCH}/" \
    -e "s/@SIZE@/${SIZE}/" \
    "$HERE/packaging/control.in" > "$PKG/DEBIAN/control"
echo "/etc/profile.d/wsl2-ssh-agent.sh" > "$PKG/DEBIAN/conffiles"

# --- 4. Build ---
mkdir -p "$OUT"
DEB="$OUT/wsl2-ssh-agent_${VERSION}-${REVISION}_${ARCH}.deb"
dpkg-deb --root-owner-group -Zxz --build "$PKG" "$DEB" >/dev/null
echo "$DEB"
