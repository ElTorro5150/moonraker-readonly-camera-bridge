#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"

uninstall_moonbridge() {
  log "Uninstall: MoonBridge-managed components (explicit)"

  # Stop/disable services if present
  systemd_disable_stop "xl-cam-feed.service"
  systemd_disable_stop "xl-cam-http.service"
  systemd_disable_stop "prusa-connect-snapshot.service"

  # Remove systemd units (only the ones MoonBridge installs)
  for f in /etc/systemd/system/xl-cam-feed.service \
           /etc/systemd/system/xl-cam-http.service \
           /etc/systemd/system/prusa-connect-snapshot.service; do
    if [ -e "$f" ]; then
      backup_file "$f"
      sudo rm -f "$f"
      log "Removed: $f"
    fi
  done

  systemd_daemon_reload

  # Remove nginx site + symlink
  if [ -L /etc/nginx/sites-enabled/moonbridge ] || [ -e /etc/nginx/sites-enabled/moonbridge ]; then
    backup_file /etc/nginx/sites-enabled/moonbridge
    sudo rm -f /etc/nginx/sites-enabled/moonbridge
    log "Removed: /etc/nginx/sites-enabled/moonbridge"
  fi
  if [ -e /etc/nginx/sites-available/moonbridge ]; then
    backup_file /etc/nginx/sites-available/moonbridge
    sudo rm -f /etc/nginx/sites-available/moonbridge
    log "Removed: /etc/nginx/sites-available/moonbridge"
  fi

  # Remove installed scripts (only the ones MoonBridge installs)
  for f in /usr/local/bin/xl_cam_raw_mjpeg.sh /usr/local/bin/mjpeg_http_server.py; do
    if [ -e "$f" ]; then
      backup_file "$f"
      sudo rm -f "$f"
      log "Removed: $f"
    fi
  done

  # Keep /etc/moonbridge/prusa-connect.env by default (contains secrets)
  if [ -f /etc/moonbridge/prusa-connect.env ]; then
    warn "Keeping /etc/moonbridge/prusa-connect.env (contains secrets). Remove manually if desired."
  fi

  # Remove component staging dir
  if [ -d /usr/local/lib/moonbridge/prusa-connect-snapshot ]; then
    local bak="/usr/local/lib/moonbridge/prusa-connect-snapshot.bak-$(timestamp)"
    sudo cp -a /usr/local/lib/moonbridge/prusa-connect-snapshot "$bak"
    sudo rm -rf /usr/local/lib/moonbridge/prusa-connect-snapshot
    log "Removed component dir (backup kept): $bak"
  fi

  # Reload nginx if present
  nginx_test_and_reload || true

  log "Uninstall complete."
}
