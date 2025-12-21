#!/usr/bin/env bash
set -euo pipefail

echo "[verify] moonraker-readonly-camera-bridge sanity checks"
echo

fail=0

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || { echo "  - MISSING: $1"; fail=1; }
}

echo "[verify] Required commands:"
need_cmd curl
need_cmd python3
need_cmd systemctl || true
echo

echo "[verify] Expected files:"
for f in \
  "nginx/moonraker-readonly.conf" \
  "scripts/mjpeg_http_server.py" \
  "scripts/xl_cam_raw_mjpeg.sh" \
  "systemd/klipper-mcu.service" \
  "systemd/klipper.service" \
  "systemd/moonraker.service" \
  "systemd/xl-cam-feed.service" \
  "systemd/xl-cam-http.service"
do
  if [[ -f "$f" ]]; then
    echo "  - OK: $f"
  else
    echo "  - MISSING: $f"
    fail=1
  fi
done
echo

if command -v systemctl >/dev/null 2>&1; then
  echo "[verify] systemd service status (if installed):"
  for svc in klipper-mcu klipper moonraker xl-cam-feed xl-cam-http; do
    if systemctl list-unit-files | grep -q "^${svc}\.service"; then
      systemctl --no-pager --full status "${svc}.service" >/dev/null 2>&1 \
        && echo "  - ${svc}.service: active" \
        || echo "  - ${svc}.service: not active (or needs sudo)"
    else
      echo "  - ${svc}.service: not installed"
    fi
  done
  echo
fi

echo "[verify] Optional HTTP checks (edit URLs if yours differ):"
MOONRAKER_URL="${MOONRAKER_URL:-http://127.0.0.1:7125}"
READONLY_URL="${READONLY_URL:-http://127.0.0.1:7126}"

echo "  - Moonraker: $MOONRAKER_URL"
echo "  - Read-only proxy: $READONLY_URL"
echo

check_url() {
  local name="$1" url="$2"
  if curl -fsS --max-time 2 "$url" >/dev/null 2>&1; then
    echo "  - OK: $name reachable ($url)"
  else
    echo "  - NOTE: $name not reachable ($url) (may be normal if not running locally)"
  fi
}

check_url "Moonraker (server/info)" "${MOONRAKER_URL}/server/info"
check_url "Read-only proxy (server/info)" "${READONLY_URL}/server/info"

echo
if [[ "$fail" -ne 0 ]]; then
  echo "[verify] FAIL: missing requirements listed above."
  exit 1
fi
echo "[verify] PASS"
