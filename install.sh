#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

NGINX_SRC="${REPO_DIR}/nginx/moonraker-readonly.conf"
MJPEG_SRC="${REPO_DIR}/scripts/mjpeg_http_server.py"
SYSTEMD_DIR="${REPO_DIR}/systemd"
PC_DIR="${REPO_DIR}/prusa-connect-snapshot"

NGINX_AVAIL="/etc/nginx/sites-available/moonraker-readonly"
NGINX_ENABLED="/etc/nginx/sites-enabled/moonraker-readonly"

MJPEG_DST="/usr/local/bin/mjpeg_http_server.py"

PC_LIB_DIR="/usr/local/lib/prusa-connect-snapshot"
PC_ETC_DIR="/etc/prusa-connect-snapshot"
PC_ENV="${PC_ETC_DIR}/prusa-connect.env"
PC_ENV_EXAMPLE_1="${PC_DIR}/config/prusa-connect.env.example"
PC_ENV_EXAMPLE_2="${PC_DIR}/prusa-connect.env.example"

say() { echo -e "\n==> $*\n"; }
die() { echo "ERROR: $*" >&2; exit 1; }

need_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    die "Please run with sudo: sudo $0 ${1:-}"
  fi
}

have_cmd() { command -v "$1" >/dev/null 2>&1; }

install_file() {
  local mode="$1" src="$2" dst="$3"
  [[ -f "$src" ]] || die "Missing file: $src"
  install -m "$mode" -D "$src" "$dst"
}

install_dir_contents() {
  local src="$1" dst="$2"
  [[ -d "$src" ]] || die "Missing dir: $src"
  mkdir -p "$dst"
  rsync -a --delete "$src"/ "$dst"/
}

maybe_create_env_stub() {
  mkdir -p "$PC_ETC_DIR"
  if [[ -f "$PC_ENV" ]]; then
    say "Env exists: $PC_ENV (leaving as-is)"
    return 0
  fi

  local example=""
  if [[ -f "$PC_ENV_EXAMPLE_1" ]]; then example="$PC_ENV_EXAMPLE_1"; fi
  if [[ -z "$example" && -f "$PC_ENV_EXAMPLE_2" ]]; then example="$PC_ENV_EXAMPLE_2"; fi

  if [[ -n "$example" ]]; then
    say "No env found. Creating a NEW template (NOT enabled) at: ${PC_ENV}.NEW"
    install -m 0600 -D "$example" "${PC_ENV}.NEW"
    echo "NOTE: Copy ${PC_ENV}.NEW to ${PC_ENV} and fill in real values on the Pi (do NOT commit)." >&2
  else
    say "No env found and no example available. Skipping env template creation."
  fi
}

nginx_install() {
  say "Installing nginx site config"
  install_file 0644 "$NGINX_SRC" "$NGINX_AVAIL"
  ln -sfn "$NGINX_AVAIL" "$NGINX_ENABLED"

  if have_cmd nginx; then
    nginx -t
    systemctl reload nginx || systemctl restart nginx
  else
    say "nginx not found; skipping reload"
  fi
}

systemd_install() {
  say "Installing systemd unit files"
  [[ -d "$SYSTEMD_DIR" ]] || die "Missing systemd folder: $SYSTEMD_DIR"

  if [[ -f "${SYSTEMD_DIR}/xl-cam-http.service" ]]; then
    install_file 0644 "${SYSTEMD_DIR}/xl-cam-http.service" "/etc/systemd/system/xl-cam-http.service"
  fi
  if [[ -f "${SYSTEMD_DIR}/prusa-connect-snapshot.service" ]]; then
    install_file 0644 "${SYSTEMD_DIR}/prusa-connect-snapshot.service" "/etc/systemd/system/prusa-connect-snapshot.service"
  fi

  systemctl daemon-reload
}

services_enable_start() {
  say "Enabling + starting services (if present)"
  if [[ -f /etc/systemd/system/xl-cam-http.service ]]; then
    systemctl enable --now xl-cam-http.service
  fi
  if [[ -f /etc/systemd/system/prusa-connect-snapshot.service ]]; then
    systemctl enable --now prusa-connect-snapshot.service
  fi
}

services_stop_disable() {
  say "Stopping + disabling services (if present)"
  systemctl disable --now prusa-connect-snapshot.service 2>/dev/null || true
  systemctl disable --now xl-cam-http.service 2>/dev/null || true
}

install_all() {
  need_root install
  have_cmd rsync || die "rsync is required (sudo apt-get install rsync)"

  say "Installing mjpeg_http_server.py"
  install_file 0755 "$MJPEG_SRC" "$MJPEG_DST"

  say "Installing Prusa Connect snapshot component to $PC_LIB_DIR"
  mkdir -p "$PC_LIB_DIR"

  # Copy runtime bits if present (prefer explicit files)
  if [[ -f "${PC_DIR}/pc_run_loop.sh" ]]; then
    install_file 0755 "${PC_DIR}/pc_run_loop.sh" "${PC_LIB_DIR}/pc_run_loop.sh"
  fi
  if [[ -f "${PC_DIR}/pc_capture_one_frame.py" ]]; then
    install_file 0755 "${PC_DIR}/pc_capture_one_frame.py" "${PC_LIB_DIR}/pc_capture_one_frame.py"
  fi

  maybe_create_env_stub
  systemd_install
  nginx_install
  services_enable_start

  say "Done."
  status || true
}

uninstall_all() {
  need_root uninstall
  services_stop_disable

  say "Removing installed files (keeps /etc/prusa-connect-snapshot/prusa-connect.env)"
  rm -f "/etc/systemd/system/prusa-connect-snapshot.service" "/etc/systemd/system/xl-cam-http.service"
  systemctl daemon-reload

  rm -f "$NGINX_ENABLED" "$NGINX_AVAIL"
  if have_cmd nginx; then
    nginx -t && systemctl reload nginx || true
  fi

  rm -f "$MJPEG_DST"
  rm -rf "$PC_LIB_DIR"

  say "Keeping $PC_ENV and $PC_ETC_DIR intact."
  say "Uninstall complete."
}

status() {
  say "Repo: $REPO_DIR"
  echo "nginx src: $NGINX_SRC"
  echo "mjpeg src: $MJPEG_SRC"
  echo "pc dir:    $PC_DIR"
  echo

  echo "Installed:"
  ls -l "$MJPEG_DST" 2>/dev/null || true
  ls -l "$NGINX_AVAIL" "$NGINX_ENABLED" 2>/dev/null || true
  ls -l "/etc/systemd/system/xl-cam-http.service" "/etc/systemd/system/prusa-connect-snapshot.service" 2>/dev/null || true
  echo

  echo "Services:"
  systemctl --no-pager --full status xl-cam-http.service 2>/dev/null || true
  systemctl --no-pager --full status prusa-connect-snapshot.service 2>/dev/null || true
}

restart_services() {
  need_root restart
  say "Restarting services"
  systemctl restart xl-cam-http.service 2>/dev/null || true
  systemctl restart prusa-connect-snapshot.service 2>/dev/null || true
  status || true
}

usage() {
  cat <<USAGE
Usage: sudo ./install.sh <command>

Commands:
  install     Install/update all components (idempotent)
  uninstall   Remove installed files (keeps /etc/prusa-connect-snapshot/prusa-connect.env)
  status      Show what's installed and service status
  restart     Restart services
USAGE
}

cmd="${1:-}"
case "$cmd" in
  install)   install_all ;;
  uninstall) uninstall_all ;;
  status)    status ;;
  restart)   restart_services ;;
  *) usage; exit 1 ;;
esac
