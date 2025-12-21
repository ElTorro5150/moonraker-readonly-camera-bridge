#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<USAGE
Usage: sudo ./install/install_host_mcu.sh [--enable]

Idempotent installer for this repo:
  - Installs systemd unit files from ./systemd into /etc/systemd/system/
  - Optionally enables/starts services (with --enable)
  - Installs nginx read-only site config to /etc/nginx/sites-enabled/moonraker-readonly

Notes:
  - Run from the repo root (or it will auto-detect via git).
  - This does NOT edit your Moonraker/Klipper configs.
USAGE
}

ENABLE=0
if [[ "${1:-}" == "--help" ]]; then usage; exit 0; fi
if [[ "${1:-}" == "--enable" ]]; then ENABLE=1; fi

if [[ "$(id -u)" -ne 0 ]]; then
  echo "ERROR: run as root (use sudo)";
  exit 1
fi

# Find repo root
REPO_ROOT=""
if command -v git >/dev/null 2>&1; then
  REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
fi
if [[ -z "$REPO_ROOT" ]]; then
  echo "ERROR: not in a git repo. Run this from inside the repo.";
  exit 1
fi

echo "[install] Repo root: $REPO_ROOT"

# 1) Install systemd unit files
echo "[install] Installing systemd unit files to /etc/systemd/system/ ..."
install -d /etc/systemd/system
for f in "$REPO_ROOT"/systemd/*.service; do
  [[ -f "$f" ]] || continue
  install -m 0644 "$f" "/etc/systemd/system/$(basename "$f")"
  echo "  - installed: $(basename "$f")"
done

echo "[install] systemd daemon-reload"
systemctl daemon-reload

# 2) Install nginx site config (read-only proxy)
if [[ -f "$REPO_ROOT/nginx/moonraker-readonly.conf" ]]; then
  echo "[install] Installing nginx site: /etc/nginx/sites-enabled/moonraker-readonly"
  install -d /etc/nginx/sites-enabled
  install -m 0644 "$REPO_ROOT/nginx/moonraker-readonly.conf" /etc/nginx/sites-enabled/moonraker-readonly
  echo "[install] nginx config test"
  nginx -t
  echo "[install] reload nginx"
  systemctl reload nginx
else
  echo "[install] NOTE: nginx/moonraker-readonly.conf not found in repo; skipping nginx install."
fi

# 3) Optionally enable/start services
if [[ "$ENABLE" -eq 1 ]]; then
  echo "[install] Enabling + starting services (if present)..."
  for svc in klipper-mcu klipper moonraker xl-cam-feed xl-cam-http; do
    if [[ -f "/etc/systemd/system/${svc}.service" ]]; then
      systemctl enable --now "${svc}.service" || true
      echo "  - attempted start: ${svc}.service"
    else
      echo "  - not installed: ${svc}.service"
    fi
  done
else
  echo "[install] Skipping enable/start (run with --enable to start services)";
fi

echo "[install] DONE"
