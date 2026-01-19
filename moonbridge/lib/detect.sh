#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"

preflight() {
  need_cmd bash
  need_cmd sudo
  need_cmd systemctl
  need_cmd nginx

  if ! have_cmd whiptail; then
    warn "whiptail not found. Menu will fall back to a basic prompt."
    warn "Install with: sudo apt-get update && sudo apt-get install -y whiptail"
  fi

  if [ -r /etc/os-release ]; then
    . /etc/os-release
    log "Detected OS: ${PRETTY_NAME:-unknown}"
  else
    warn "Cannot read /etc/os-release"
  fi
}
