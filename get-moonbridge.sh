#!/usr/bin/env bash
set -euo pipefail

# MoonBridge one-command bootstrapper
# - Refuses to run as root
# - Requires: git
# - Clones repo into $HOME/repo/moonraker-readonly-camera-bridge (or timestamped variant)
# - Launches ./run-moonbridge.sh

if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
  echo "ERROR: Do not run this as root."
  echo "Run as a normal user."
  exit 1
fi

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "ERROR: Missing required command: $1"
    exit 1
  }
}

need_cmd git

OWNER="ElTorro5150"
REPO="moonraker-readonly-camera-bridge"
BRANCH="main"

REPO_URL="https://github.com/${OWNER}/${REPO}.git"

BASE_DIR="${HOME}/repo"
DEFAULT_DIR="${BASE_DIR}/${REPO}"

mkdir -p "$BASE_DIR"

TARGET_DIR="$DEFAULT_DIR"
if [[ -e "$TARGET_DIR" ]]; then
  TS="$(date +%Y%m%d_%H%M%S)"
  TARGET_DIR="${DEFAULT_DIR}-${TS}"
fi

echo "MoonBridge bootstrapper"
echo "Cloning:  $REPO_URL"
echo "Branch:   $BRANCH"
echo "Into:     $TARGET_DIR"
echo

git clone --depth 1 --branch "$BRANCH" "$REPO_URL" "$TARGET_DIR"

cd "$TARGET_DIR"

if [[ ! -f "./run-moonbridge.sh" ]]; then
  echo "ERROR: run-moonbridge.sh not found in cloned repo."
  echo "Expected: $TARGET_DIR/run-moonbridge.sh"
  exit 1
fi

chmod +x ./run-moonbridge.sh || true

echo
echo "Launching installer menu..."
echo

exec ./run-moonbridge.sh
