#!/usr/bin/env bash
set -euo pipefail

# Safe MoonBridge launcher
# - refuses to run as root
# - launches the menu installer: moonbridge/moonbridge.sh
# - menu should use sudo only when required

if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
  echo "ERROR: Do not run this as root."
  echo "Run as a normal user: ./run-moonbridge.sh"
  exit 1
fi

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
