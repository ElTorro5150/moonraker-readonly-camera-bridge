#!/usr/bin/env bash
set -euo pipefail

# Safe MoonBridge launcher
# - refuses to run as root
# - launches the menu installer: moonbridge/moonbridge.sh
# - menu should use sudo only when required

# MB_PATCH_BOOTSTRAP_DEPS: install required packages on first run (Debian/RPi OS)
ensure_deps() {
  # Keep this list minimal + safe. Add more here if the installer grows.
  local pkgs=(git whiptail curl ca-certificates nginx)

  if ! command -v apt-get >/dev/null 2>&1; then
    echo "[MoonBridge][ERROR] apt-get not found. Install dependencies manually: ${pkgs[*]}" >&2
    return 1
  fi

  if ! command -v dpkg >/dev/null 2>&1; then
    echo "[MoonBridge][ERROR] dpkg not found. Install dependencies manually: ${pkgs[*]}" >&2
    return 1
  fi

  local missing=()
  local pkg
  for pkg in "${pkgs[@]}"; do
    dpkg -s "$pkg" >/dev/null 2>&1 || missing+=("$pkg")
  done

  if ((${#missing[@]})); then
    echo "[MoonBridge] Installing dependencies: ${missing[*]}"
    sudo apt-get update
    sudo apt-get install -y "${missing[@]}"
  fi

  return 0
}

if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
  echo "ERROR: Do not run this as root."
  echo "Run as a normal user: ./run-moonbridge.sh"
  exit 1
fi

ensure_deps || exit 1


REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
MENU="${REPO_ROOT}/moonbridge/moonbridge.sh"

if [[ ! -f "$MENU" ]]; then
  echo "ERROR: Menu installer not found: $MENU"
  exit 1
fi

if [[ ! -x "$MENU" ]]; then
  chmod +x "$MENU" || true
fi

echo "MoonBridge launcher"
echo "Repo:      $REPO_ROOT"
echo "Launching: $MENU"
echo

exec "$MENU"
