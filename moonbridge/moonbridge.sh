#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/moonbridge/lib/common.sh"
source "$ROOT_DIR/moonbridge/lib/detect.sh"
source "$ROOT_DIR/moonbridge/lib/install_streaming.sh"
source "$ROOT_DIR/moonbridge/lib/install_snapshots.sh"
source "$ROOT_DIR/moonbridge/lib/install_full.sh"
source "$ROOT_DIR/moonbridge/lib/snapshot_interval.sh"
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

banner() {
  cat <<'EOF'
================================
           MoonBridge
================================
Read-Only Camera & Snapshot Gateway
EOF
}

# Put SAFE ASCII art here (keep it PG/PG-13).
easter_egg_art() {
  cat <<'EOF'
bob goatse wuz here
 /     \             \            /    \
|       |             \          |      |
|       `.             |         |       :
`        |             |        \|       |
 \       | /       /  \\\   --__ \\       :
  \      \/   _--~~          ~--__| \     |
   \      \_-~                    ~-_\    |
    \_     \        _.--------.______\|   |
      \     \______// _ ___ _ (_(__>  \   |
       \   .  C ___)  ______ (_(____>  |  /
       /\ |   C ____)/      \ (_____>  |_/
      / /\|   C_____)       |  (___>   /  \
     |   (   _C_____)\______/  // _/ /     \
     |    \  |__   \\_________// (__/       |
    | \    \____)   `----   --'             |
    |  \_          ___\       /_          _/ |
   |              /    |     |  \            |
   |             |    /       \  \           |
   |          / /    |         |  \           |
   |         / /      \__/\___/    |          |
  |           /        |    |       |         |
  |          |         |    |       |         |

EOF
}

easter_egg() {
  clear || true
  easter_egg_art
  echo
  local n
  n=$(( (RANDOM % 11) + 5 ))  # 5..15
  while (( n > 0 )); do
    printf "\rReturning you to the installer menu in %2d seconds... " "$n"
    sleep 1
    n=$((n - 1))
  done
  echo
  sleep 0.2
}

about_screen() {
  while true; do
    clear || true
    banner
    echo
    echo "MoonBridge — Read-Only Camera & Snapshot Gateway"
    echo
    echo "Press 'q' to return to the installer menu."
#   echo "(Any other key triggers a secret.)"
    echo

    # Read exactly one key (works over SSH)
    IFS= read -r -n 1 -s key || key="q"
    if [[ "$key" == "q" || "$key" == "Q" ]]; then
      return 0
    fi

    # Anything else => easter egg, then back to About
    easter_egg
  done
}

menu_loop() {
  while true; do
    local choice=""

    if command -v whiptail >/dev/null 2>&1; then
      choice="$(whiptail --title "MoonBridge" --menu "Select an option:" 20 78 12 \
        "1" "Install: MobileRaker Streaming Only" \
        "2" "Install: Prusa Connect Snapshots Only" \
        "3" "Install: Full Install" \
        "4" "Status / Health Check" \
        "5" "Set Snapshot Upload Interval" \
        "6" "About" \
        "7" "Uninstall (explicit)" \
        "8" "Exit" \
        3>&1 1>&2 2>&3 || true)"
    else
      clear || true
      banner
      echo
      echo "1) Streaming Only"
      echo "2) Snapshots Only"
      echo "3) Full Install"
      echo "4) Status"
      echo "5) Set Snapshot Interval"
      echo "6) About"
      echo "7) Uninstall"
      echo "8) Exit"
      read -r -p "Choice: " choice
    fi

    case "${choice:-8}" in
      1)
        confirm $'Install Streaming Only?\n\n- Installs xl-cam services\n- Installs nginx site on :7126\n- Enables + starts services\n' && install_streaming
        ;;
      2)
        confirm $'Install Snapshots Only?\n\n- Installs prusa-connect-snapshot service\n- Sets up env file path\n- Enables + starts service (once configured)\n' && install_snapshots
        ;;
      3)
        confirm $'Install Full?\n\n- Installs Streaming + nginx\n- Installs Snapshots\n' && install_full
        ;;
      4)
        show_status
        if command -v whiptail >/dev/null 2>&1; then
          whiptail --title "MoonBridge" --msgbox "Done. Press Enter to return." 10 60
        else
          echo
          read -r -p "Press Enter to return to menu..." _
        fi
        ;;
      5)
        set_snapshot_interval || true
        ;;
      6)
        about_screen
        ;;
      7)
        confirm $'Uninstall MoonBridge-managed components?\n\nThis stops/disables services and removes MoonBridge-managed files.\n' && uninstall_moonbridge
        ;;
      8|*)
        log "Exit."
        return 0
        ;;
    esac
  done
}

main() {
  log "MoonBridge - menu installer"
  preflight
  menu_loop
}

main "$@"
