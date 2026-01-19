#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"

install_streaming() {
  log "Install: MobileRaker Streaming Only"

  # Repo paths (source-of-truth)
  local repo_root
  repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

  local src_feed="${repo_root}/systemd/xl-cam-feed.service"
  local src_http="${repo_root}/systemd/xl-cam-http.service"
  local src_raw="${repo_root}/scripts/xl_cam_raw_mjpeg.sh"
  local src_py="${repo_root}/scripts/mjpeg_http_server.py"
  local src_ng="${repo_root}/nginx/moonraker-readonly.conf"

  # Install locations
  local dst_feed="/etc/systemd/system/xl-cam-feed.service"
  local dst_http="/etc/systemd/system/xl-cam-http.service"
  local dst_raw="/usr/local/bin/xl_cam_raw_mjpeg.sh"
  local dst_py="/usr/local/bin/mjpeg_http_server.py"

  local ng_avail="/etc/nginx/sites-available/moonbridge"
  local ng_enabled="/etc/nginx/sites-enabled/moonbridge"

  # Install scripts
  install_file_idempotent "$src_raw" "$dst_raw" 0755
  install_file_idempotent "$src_py"  "$dst_py"  0755

  # Install systemd units
  install_file_idempotent "$src_feed" "$dst_feed" 0644
  install_file_idempotent "$src_http" "$dst_http" 0644

  # Install nginx site
  install_file_idempotent "$src_ng" "$ng_avail" 0644
  symlink_idempotent "$ng_avail" "$ng_enabled"

  systemd_daemon_reload
  systemd_enable_now "xl-cam-feed.service"
  systemd_enable_now "xl-cam-http.service"

  nginx_test_and_reload

  log "Verification tips:"
  log "  - curl -I http://127.0.0.1:7126/stream.mjpg"
  log "  - curl -I http://127.0.0.1:7126/snapshot.jpg"
}
