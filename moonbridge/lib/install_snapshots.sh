#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"

ENV_DIR="/etc/prusa-connect-snapshot"
ENV_PATH="/etc/prusa-connect-snapshot/prusa-connect.env"

env_has_real_values() {
  [ -f "$ENV_PATH" ] || return 1
  grep -qE '^[[:space:]]*(PRUSA_CONNECT_TOKEN|TOKEN)=.+[^[:space:]]' "$ENV_PATH" || return 1
  grep -qE '^[[:space:]]*(PRUSA_CONNECT_FINGERPRINT|FINGERPRINT)=.+[^[:space:]]' "$ENV_PATH" || return 1
  grep -qiE 'CHANGE_ME|REPLACE_ME|YOUR_TOKEN|YOUR_FINGERPRINT|<|>' "$ENV_PATH" && return 1
  return 0
}

install_snapshots() {
  log "Install: Prusa Connect Snapshots Only"

  local repo_root
  repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

  local src_unit="${repo_root}/systemd/prusa-connect-snapshot.service"
  local dst_unit="/etc/systemd/system/prusa-connect-snapshot.service"

  # Match your live layout
  local src_component="${repo_root}/prusa-connect-snapshot"
  local dst_component="/usr/local/lib/prusa-connect-snapshot"

  # Ensure env dir exists
  ensure_dir_mode "$ENV_DIR" 0755

  # Install/refresh component dir (backup then replace if exists)
  if [ -d "$dst_component" ] && [ -n "$(ls -A "$dst_component" 2>/dev/null || true)" ]; then
    local bak="${dst_component}.bak-$(timestamp)"
    sudo cp -a "$dst_component" "$bak"
    log "Backed up component dir: $dst_component -> $bak"
    sudo rm -rf "$dst_component"
  fi
  sudo mkdir -p "$dst_component"
  sudo cp -a "$src_component/." "$dst_component/"
  log "Installed component to: $dst_component"

  # Install systemd unit (idempotent)
  install_file_idempotent "$src_unit" "$dst_unit" 0644

  # Create env file from example if it doesn't exist
  local src_env_example="${dst_component}/config/prusa-connect.env.example"
  if [ ! -f "$ENV_PATH" ]; then
    if [ -f "$src_env_example" ]; then
      sudo install -m 0600 "$src_env_example" "$ENV_PATH"
      log "Created env file from example: $ENV_PATH"
    else
      sudo bash -lc "cat > '$ENV_PATH' <<'EOT'
# Prusa Connect env (DO NOT COMMIT)
PRUSA_CONNECT_TOKEN=
PRUSA_CONNECT_FINGERPRINT=
EOT"
      sudo chmod 0600 "$ENV_PATH"
      log "Created minimal env file: $ENV_PATH"
    fi
  else
    sudo chmod 0600 "$ENV_PATH"
    log "Env file exists: $ENV_PATH (permissions enforced 0600)"
  fi

  systemd_daemon_reload

  if env_has_real_values; then
    systemd_enable_now "prusa-connect-snapshot.service"
    log "Prusa Connect service started (env appears filled)."
  else
    warn "Env file is not filled yet. Service will NOT be started."
    warn "Edit: sudo nano $ENV_PATH"
    warn "Then: sudo systemctl enable --now prusa-connect-snapshot.service"
  fi
}
