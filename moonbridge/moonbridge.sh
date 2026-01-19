#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/moonbridge/lib/common.sh"
source "$ROOT_DIR/moonbridge/lib/detect.sh"
source "$ROOT_DIR/moonbridge/lib/install_streaming.sh"
source "$ROOT_DIR/moonbridge/lib/install_snapshots.sh"
source "$ROOT_DIR/moonbridge/lib/install_full.sh"
source "$ROOT_DIR/moonbridge/lib/status.sh"
source "$ROOT_DIR/moonbridge/lib/uninstall.sh"

confirm() {
  local msg="$1"
  if command -v whiptail >/dev/null 2>&1; then
    whiptail --title "MoonBridge" --yesno "$msg" 12 78
  else
    read -r -p "$msg [y/N]: " ans
    [[ "${ans:-}" =~ ^[Yy]$ ]]
  fi
}

main() {
  log "MoonBridge — menu installer"
  preflight

  local choice=""
  if command -v whiptail >/dev/null 2>&1; then
    choice="$(whiptail --title "MoonBridge" --menu "Select an option:" 20 78 10 \
      "1" "Install: MobileRaker Streaming Only" \
      "2" "Install: Prusa Connect Snapshots Only" \
      "3" "Install: Full Install" \
      "4" "Status / Health Check" \
      "5" "Uninstall (explicit)" \
      "6" "Exit" \
      3>&1 1>&2 2>&3 || true)"
  else
    echo "1) Streaming Only"
    echo "2) Snapshots Only"
    echo "3) Full Install"
    echo "4) Status"
    echo "5) Uninstall"
    echo "6) Exit"
    read -r -p "Choice: " choice
  fi

  case "${choice:-6}" in
    1)
      confirm "Install Streaming Only?\n\n- Installs xl-cam services\n- Installs nginx site on :7126\n- Enables + starts services\n" && install_streaming
      ;;
    2)
      confirm "Install Snapshots Only?\n\n- Installs prusa-connect-snapshot service\n- Creates /etc/moonbridge/prusa-connect.env (placeholders)\n- Will NOT start service until env appears filled\n" && install_snapshots
      ;;
    3)
      confirm "Install Full?\n\n- Installs Streaming + nginx\n- Installs Snapshots (env placeholders)\n" && install_full
      ;;
    4) show_status ;;
    5)
      confirm "Uninstall MoonBridge-managed components?\n\nThis stops/disables services and removes:\n- /etc/systemd/system/xl-cam-*.service\n- /etc/nginx/sites-{available,enabled}/moonbridge\n- /usr/local/bin/{xl_cam_raw_mjpeg.sh,mjpeg_http_server.py}\n\nIt keeps /etc/moonbridge/prusa-connect.env (secrets).\n" && uninstall_moonbridge
      ;;
    *) log "Exit." ;;
  esac
}

main "$@"
