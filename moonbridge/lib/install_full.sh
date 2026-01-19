#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/install_streaming.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/install_snapshots.sh"

install_full() {
  log "Install: Full Install"
  install_streaming
  install_snapshots
}
