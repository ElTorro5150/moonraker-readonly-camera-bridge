#!/usr/bin/env bash
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "Run with sudo: sudo $0" >&2
  exit 1
fi

# Find repo root relative to this script
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC_DIR="$REPO_ROOT/prusa-connect-snapshot"

echo "[1/6] Install program files..."
install -d /usr/local/bin
install -d /usr/local/lib/prusa-connect-snapshot

install -m 0755 "$SRC_DIR/bin/mjpeg_http_server.py" /usr/local/bin/mjpeg_http_server.py
install -m 0755 "$SRC_DIR/bin/xl_cam_raw_mjpeg.sh"  /usr/local/bin/xl_cam_raw_mjpeg.sh

install -m 0755 "$SRC_DIR/bin/pc_run_loop.sh"        /usr/local/lib/prusa-connect-snapshot/pc_run_loop.sh
install -m 0755 "$SRC_DIR/bin/pc_upload_snapshot.py" /usr/local/lib/prusa-connect-snapshot/pc_upload_snapshot.py

if [[ -f "$SRC_DIR/bin/pc_capture_one_frame.py" ]]; then
  install -m 0755 "$SRC_DIR/bin/pc_capture_one_frame.py" /usr/local/lib/prusa-connect-snapshot/pc_capture_one_frame.py
fi

echo "[2/6] Install systemd units..."
install -d /etc/systemd/system
install -m 0644 "$SRC_DIR/systemd/xl-cam-feed.service" /etc/systemd/system/xl-cam-feed.service
install -m 0644 "$SRC_DIR/systemd/xl-cam-http.service" /etc/systemd/system/xl-cam-http.service
install -m 0644 "$SRC_DIR/systemd/prusa-connect-snapshot.service" /etc/systemd/system/prusa-connect-snapshot.service

echo "[3/6] Install config (only if missing)..."
install -d /etc/prusa-connect-snapshot
if [[ ! -f /etc/prusa-connect-snapshot/prusa-connect.env ]]; then
  install -m 0600 "$SRC_DIR/config/prusa-connect.env.example" /etc/prusa-connect-snapshot/prusa-connect.env
  echo "Created /etc/prusa-connect-snapshot/prusa-connect.env (EDIT IT NOW)"
else
  echo "Keeping existing /etc/prusa-connect-snapshot/prusa-connect.env"
fi

echo "[4/6] Reload systemd..."
systemctl daemon-reload

echo "[5/6] Enable services..."
systemctl enable xl-cam-feed.service
systemctl enable xl-cam-http.service
systemctl enable prusa-connect-snapshot.service

echo "[6/6] Done."
echo "Next steps:"
echo "  sudo nano /etc/prusa-connect-snapshot/prusa-connect.env"
echo "  sudo systemctl start xl-cam-feed xl-cam-http prusa-connect-snapshot"
