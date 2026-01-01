#!/usr/bin/env bash
set -e

if [[ $EUID -ne 0 ]]; then
  echo "ERROR: This installer must be run as root."
  echo "Run: sudo ./install.sh"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SNAPSHOT_DIR="$SCRIPT_DIR/prusa-connect-snapshot"

if [[ ! -d "$SNAPSHOT_DIR" ]]; then
  echo "ERROR: prusa-connect-snapshot directory not found"
  exit 1
fi

echo "==> Installing Prusa Connect Snapshot add-on"
cd "$SNAPSHOT_DIR"

if [[ ! -x install.sh ]]; then
  echo "ERROR: prusa-connect-snapshot/install.sh not found or not executable"
  exit 1
fi

./install.sh

echo "==> Installation complete"
