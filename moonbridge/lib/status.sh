#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"

svc_exists() {
  local svc="$1"
  systemctl status "$svc" >/dev/null 2>&1
}

http_code_get() {
  # http_code_get <url>
  local url="$1"
  if have_cmd curl; then
    # Use GET (not HEAD) because mjpeg_http_server.py returns 501 on HEAD.
    # For stream.mjpg, request just 1 byte so we don't hang.
    if [[ "$url" == *"/stream.mjpg" ]]; then
      curl -sS --max-time 3 --range 0-0 -o /dev/null -w "%{http_code}" "$url" || echo "ERR"
    else
      curl -sS --max-time 3 -o /dev/null -w "%{http_code}" "$url" || echo "ERR"
    fi
  else
    echo "NO_CURL"
  fi
}

show_status() {
  log "Status / Health Check"

  log "== Services =="
  for svc in xl-cam-feed.service xl-cam-http.service prusa-connect-snapshot.service nginx.service; do
    if svc_exists "$svc"; then
      local active enabled
      active="$(systemctl is-active "$svc" 2>/dev/null || true)"
      enabled="$(systemctl is-enabled "$svc" 2>/dev/null || true)"
      log "$svc  active=$active  enabled=$enabled"
    else
      log "$svc  (not found)"
    fi
  done
  echo

  log "== Endpoints (GET checks, local) =="
  log "7126/stream.mjpg    -> $(http_code_get "http://127.0.0.1:7126/stream.mjpg")"
  log "7126/snapshot.jpg   -> $(http_code_get "http://127.0.0.1:7126/snapshot.jpg")"
  log "7126/server/info    -> $(http_code_get "http://127.0.0.1:7126/server/info")"
  echo

  log "== Files =="
  ls -l /etc/nginx/sites-available/moonbridge 2>/dev/null || true
  ls -l /etc/nginx/sites-enabled/moonbridge 2>/dev/null || true
  ls -l /etc/moonbridge/prusa-connect.env 2>/dev/null || true

  # Also show whether your nginx site exists outside MoonBridge naming
  ls -l /etc/nginx/sites-available 2>/dev/null | sed -n '1,200p' || true
}
