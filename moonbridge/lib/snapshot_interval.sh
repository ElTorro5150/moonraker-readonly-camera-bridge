#!/usr/bin/env bash
set -euo pipefail

# Snapshot interval helper
# Updates INTERVAL_SECONDS in /etc/prusa-connect-snapshot/prusa-connect.env
# Then restarts prusa-connect-snapshot.service

ENV_FILE="/etc/prusa-connect-snapshot/prusa-connect.env"
SERVICE_NAME="prusa-connect-snapshot.service"

log() { echo "[MoonBridge] $*"; }
have_whiptail() { command -v whiptail >/dev/null 2>&1; }

require_sudo() {
  if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    sudo -v
  fi
}

read_current_interval() {
  if [[ -f "$ENV_FILE" ]]; then
    sed -n 's/^[[:space:]]*INTERVAL_SECONDS[[:space:]]*=[[:space:]]*//p' "$ENV_FILE" | tail -n 1
  fi
}

is_int() { [[ "${1:-}" =~ ^[0-9]+$ ]]; }

prompt_interval() {
  local current="${1:-}"
  local default="${current:-60}"
  local input=""

  if have_whiptail; then
    # IMPORTANT: do NOT "|| true" here; we need exit status to detect Cancel.
    input="$(whiptail --title "MoonBridge" \
      --inputbox "Set Prusa Connect snapshot upload interval (seconds)\n\nCurrent: ${current:-not set}\n\nRecommended: 30–120 (5 allowed)\nMin 5, Max 3600\n\nCancel = no change" \
      15 72 "$default" 3>&1 1>&2 2>&3)"
    # If user pressed Cancel, whiptail exits non-zero and set -e would stop us.
    # So we only get here on OK.
  else
    echo
    echo "Set Prusa Connect snapshot upload interval (seconds)"
    echo "Current: ${current:-not set}"
    echo "Recommended: 30–120 (5 allowed)"
    echo "Min 5, Max 3600"
    echo "Press Enter for default, or type 'q' to cancel."
    read -r -p "New interval in seconds [${default}]: " input
    input="${input:-$default}"
    if [[ "${input,,}" == "q" || "${input,,}" == "quit" || "${input,,}" == "cancel" ]]; then
      return 1
    fi
  fi

  # If user hit OK but cleared the box, treat as default/current.
  if [[ -z "${input:-}" ]]; then
    input="$default"
  fi

  echo "$input"
}

update_env_interval() {
  local new_val="$1"

  # Create file if missing (do not touch other keys)
  if [[ ! -f "$ENV_FILE" ]]; then
    sudo install -m 0600 -D /dev/null "$ENV_FILE"
  fi

  # Replace ALL occurrences (avoids ambiguity). If none exists, append.
  if sudo grep -qE '^[[:space:]]*INTERVAL_SECONDS[[:space:]]*=' "$ENV_FILE"; then
    sudo sed -i -E "s/^[[:space:]]*INTERVAL_SECONDS[[:space:]]*=.*$/INTERVAL_SECONDS=${new_val}/" "$ENV_FILE"
  else
    echo "INTERVAL_SECONDS=${new_val}" | sudo tee -a "$ENV_FILE" >/dev/null
  fi
}

restart_service() {
  sudo systemctl restart "$SERVICE_NAME"
}

set_snapshot_interval() {
  local current new_val attempts
  current="$(read_current_interval || true)"
  attempts=0

  while true; do
    attempts=$((attempts + 1))

    # Whiptail Cancel needs special handling:
    # - whiptail returns non-zero on Cancel
    # - because we run with set -e, we must catch it with `if ...; then ...; else ...; fi`
    if have_whiptail; then
      if ! new_val="$(prompt_interval "$current")"; then
        log "Cancelled. No changes made."
        return 0
      fi
    else
      if ! new_val="$(prompt_interval "$current")"; then
        log "Cancelled. No changes made."
        return 0
      fi
    fi

    # If user chose the same value, exit cleanly without restarting.
    if [[ -n "${current:-}" && "$new_val" == "$current" ]]; then
      log "No change (still ${current}s)."
      return 0
    fi

    if ! is_int "$new_val"; then
      log "Invalid value (not an integer): '$new_val'"
    elif (( new_val < 5 )); then
      log "Too small. Minimum is 5 seconds."
    elif (( new_val > 3600 )); then
      log "Too large. Maximum is 3600 seconds."
    else
      break
    fi

    if (( attempts >= 5 )); then
      log "Aborting: too many invalid attempts."
      return 1
    fi
  done

  if (( new_val < 15 )); then
    if command -v whiptail >/dev/null 2>&1; then
      whiptail --title "MoonBridge" --msgbox "Warning:\n\nIntervals under 15 seconds may increase CPU and bandwidth and could be rate-limited by Prusa Connect.\nRestarting the snapshot service may take a few seconds on Raspberry Pi.\n\nProceeding with INTERVAL_SECONDS=${new_val}." 13 78
    else
      echo
      log "WARNING: intervals under 15s may increase CPU and bandwidth and could be rate-limited by Prusa Connect."
      echo
      input=""
      read -r -p "Press Enter to continue..." input
    fi
  fi

  log "Updating ${ENV_FILE}: INTERVAL_SECONDS=${new_val}"
  require_sudo
  update_env_interval "$new_val"

  log "Restarting ${SERVICE_NAME}"
  restart_service

  log "Done. New interval: ${new_val}s"
}

