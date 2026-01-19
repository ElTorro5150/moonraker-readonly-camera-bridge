#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"

# ---------- Pretty output helpers ----------
is_tty() { [ -t 1 ]; }

# Colors (auto-disable if not a tty)
if is_tty; then
  C_RESET=$'\033[0m'
  C_DIM=$'\033[2m'
  C_OK=$'\033[32m'
  C_WARN=$'\033[33m'
  C_BAD=$'\033[31m'
  C_HEAD=$'\033[36m'
else
  C_RESET=""; C_DIM=""; C_OK=""; C_WARN=""; C_BAD=""; C_HEAD=""
fi

pill() {
  # pill OK|WARN|FAIL "message"
  local kind="$1"; shift
  local msg="$*"
  case "$kind" in
    OK)   printf "%s[ OK ]%s %s\n"   "$C_OK"   "$C_RESET" "$msg" ;;
    WARN) printf "%s[WARN]%s %s\n"   "$C_WARN" "$C_RESET" "$msg" ;;
    FAIL) printf "%s[FAIL]%s %s\n"   "$C_BAD"  "$C_RESET" "$msg" ;;
    *)    printf "[....] %s\n" "$msg" ;;
  esac
}

hdr() {
  # hdr "Title"
  printf "%s\n" "${C_HEAD}== $* ==${C_RESET}"
}

svc_exists() {
  local svc="$1"
  systemctl --system status "$svc" >/dev/null 2>&1
}

svc_state() {
  local svc="$1"
  local active enabled
  active="$(systemctl --system is-active "$svc" 2>/dev/null || true)"
  enabled="$(systemctl --system is-enabled "$svc" 2>/dev/null || true)"
  printf "%s|%s" "$active" "$enabled"
}

# ---------- HTTP checks ----------
http_code_get() {
  # http_code_get <url>
  local url="$1"
  if have_cmd curl; then
    curl -fsS --max-time 3 -o /dev/null -w "%{http_code}" "$url" 2>/dev/null || echo "000"
  else
    echo "NO_CURL"
  fi
}

http_code_stream() {
  # stream endpoints never end; read only a tiny chunk and stop cleanly.
  # This avoids the "Operation timed out ..." noise.
  local url="$1"
  if have_cmd curl; then
    # --max-time 2 keeps it quick, --range limits bytes, and we silence stderr.
    curl -fsS --max-time 2 --range 0-4095 -o /dev/null -w "%{http_code}" "$url" 2>/dev/null || echo "000"
  else
    echo "NO_CURL"
  fi
}

show_status() {
  log "Status / Health Check"

  hdr "Services"
  for svc in xl-cam-feed.service xl-cam-http.service prusa-connect-snapshot.service nginx.service; do
    if svc_exists "$svc"; then
      IFS='|' read -r active enabled <<<"$(svc_state "$svc")"
      if [[ "$active" == "active" ]]; then
        pill OK   "$svc  active=$active  enabled=$enabled"
      elif [[ "$active" == "inactive" ]]; then
        pill WARN "$svc  active=$active  enabled=$enabled"
      else
        pill FAIL "$svc  active=$active  enabled=$enabled"
      fi
    else
      pill WARN "$svc  (not found)"
    fi
  done
  echo

  hdr "Endpoints (local GET)"
  local s_code sn_code info_code
  s_code="$(http_code_stream "http://127.0.0.1:7126/stream.mjpg")"
  sn_code="$(http_code_get    "http://127.0.0.1:7126/snapshot.jpg")"
  info_code="$(http_code_get  "http://127.0.0.1:7126/server/info")"

  [[ "$s_code" == 2* ]] && pill OK "7126/stream.mjpg    -> $s_code" || pill WARN "7126/stream.mjpg    -> $s_code"
  [[ "$sn_code" == 2* ]] && pill OK "7126/snapshot.jpg   -> $sn_code" || pill WARN "7126/snapshot.jpg   -> $sn_code"
  [[ "$info_code" == 2* ]] && pill OK "7126/server/info    -> $info_code" || pill WARN "7126/server/info    -> $info_code"
  echo

  hdr "Files"
  # Nginx sites: show anything that looks like moonbridge or moonraker-readonly
  if [ -d /etc/nginx/sites-available ]; then
    ls -l /etc/nginx/sites-available 2>/dev/null | grep -E "moonbridge|moonraker-readonly" || true
  fi
  if [ -d /etc/nginx/sites-enabled ]; then
    ls -l /etc/nginx/sites-enabled 2>/dev/null | grep -E "moonbridge|moonraker-readonly" || true
  fi

  if [ -f /etc/prusa-connect-snapshot/prusa-connect.env ]; then
    ls -l /etc/prusa-connect-snapshot/prusa-connect.env
  else
    pill WARN "/etc/prusa-connect-snapshot/prusa-connect.env (missing)"
  fi

  echo
  printf "%s\n" "${C_DIM}(Tip: run 'sudo journalctl -u prusa-connect-snapshot.service -f' to watch uploader logs)${C_RESET}"
}
