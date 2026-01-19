#!/usr/bin/env bash
set -euo pipefail

log()  { echo "[MoonBridge] $*"; }
warn() { echo "[MoonBridge][WARN] $*" >&2; }
die()  { echo "[MoonBridge][ERROR] $*" >&2; exit 1; }

need_cmd() { command -v "$1" >/dev/null 2>&1 || die "Missing required command: $1"; }
have_cmd() { command -v "$1" >/dev/null 2>&1; }

timestamp() { date +"%Y%m%d-%H%M%S"; }

backup_file() {
  local path="$1"
  [ -e "$path" ] || return 0
  local bak="${path}.bak-$(timestamp)"
  sudo cp -a "$path" "$bak"
  log "Backed up: $path -> $bak"
}

files_identical() {
  local src="$1" dst="$2"
  [ -e "$dst" ] || return 1
  cmp -s "$src" "$dst"
}

install_file_idempotent() {
  # install_file_idempotent <src> <dst> <mode>
  local src="$1" dst="$2" mode="$3"
  [ -f "$src" ] || die "Source file not found: $src"

  if files_identical "$src" "$dst"; then
    log "Unchanged: $dst"
    return 0
  fi

  if [ -e "$dst" ]; then
    backup_file "$dst"
  else
    # ensure parent exists
    sudo mkdir -p "$(dirname "$dst")"
  fi

  sudo install -m "$mode" "$src" "$dst"
  log "Installed: $dst"
}

symlink_idempotent() {
  # symlink_idempotent <target> <linkpath>
  local target="$1" linkpath="$2"
  sudo mkdir -p "$(dirname "$linkpath")"
  if [ -L "$linkpath" ]; then
    local cur
    cur="$(readlink "$linkpath" || true)"
    if [ "$cur" = "$target" ]; then
      log "Unchanged symlink: $linkpath -> $target"
      return 0
    fi
    sudo rm -f "$linkpath"
  elif [ -e "$linkpath" ]; then
    backup_file "$linkpath"
    sudo rm -f "$linkpath"
  fi
  sudo ln -s "$target" "$linkpath"
  log "Symlinked: $linkpath -> $target"
}

systemd_daemon_reload() {
  sudo systemctl daemon-reload
  log "systemd daemon-reload"
}

systemd_enable_now() {
  local unit="$1"
  sudo systemctl enable --now "$unit"
  log "Enabled + started: $unit"
}

systemd_disable_stop() {
  local unit="$1"
  sudo systemctl disable --now "$unit" >/dev/null 2>&1 || true
  sudo systemctl stop "$unit" >/dev/null 2>&1 || true
  log "Disabled + stopped (if present): $unit"
}

nginx_test_and_reload() {
  sudo nginx -t
  sudo systemctl reload nginx
  log "nginx config OK; reloaded nginx"
}

ensure_dir_mode() {
  local d="$1" mode="$2"
  sudo mkdir -p "$d"
  sudo chmod "$mode" "$d"
}

