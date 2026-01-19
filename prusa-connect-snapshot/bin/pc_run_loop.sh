#!/usr/bin/env bash
set -euo pipefail


# MOONBRIDGE_LOG_POLICY_V1
log() {
  echo "$(date \'+%Y-%m-%d %H:%M:%S\') pc_run_loop: $*"
}

shutdown_trap() {
  if [ "${_SHUTDOWN_LOGGED:-0}" = "1" ]; then return 0; fi
  _SHUTDOWN_LOGGED=1
  log "Shutdown (signal/exit) — stopping snapshot loop"
}
trap shutdown_trap EXIT INT TERM

SUCCESS_LOG_INTERVAL=60
_last_success_log=0
_successes_since_log=0

# pc_run_loop.sh
# Loads config and repeatedly:
#  1) captures one JPEG frame from the local MJPEG stream
#  2) uploads it to Prusa Connect
#
# Always-on mode (v1): uploads every INTERVAL_SECONDS.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${CONFIG_FILE:-${SCRIPT_DIR}/../config/prusa-connect.env}"

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "ERROR: Config file not found: $CONFIG_FILE" >&2
  exit 2
fi

# Load env vars from config
set -a
# shellcheck disable=SC1090
source "$CONFIG_FILE"

# MOONBRIDGE_EXPORT_FROM_PC_V1
export PRUSA_CONNECT_TOKEN="${PC_TOKEN}"
export PRUSA_CONNECT_FINGERPRINT="${PC_FINGERPRINT}"

set +a

: "${PC_TOKEN:?missing PC_TOKEN}"
: "${PC_FINGERPRINT:?missing PC_FINGERPRINT}"
: "${MJPEG_URL:?missing MJPEG_URL}"
: "${INTERVAL_SECONDS:?missing INTERVAL_SECONDS}"
: "${JPEG_PATH:?missing JPEG_PATH}"

# MOONBRIDGE_STARTUP_LOG_V1
log "Startup — config ok; interval=${INTERVAL_SECONDS}s snap_url=${SNAP_URL:-http://127.0.0.1:8081/snapshot.jpg} jpeg_path=${JPEG_PATH}"

# Ensure runtime dir exists (systemd will also handle this later)
RUNDIR="$(dirname "$JPEG_PATH")"
mkdir -p "$RUNDIR"

# Simple backoff on failures (seconds)
backoff=0
max_backoff=300  # 5 minutes

while true; do
  # Small jitter to avoid perfectly regular spikes (0-1s)
  jitter=$((RANDOM % 2))

	  # Capture one frame via the dedicated single-frame endpoint (stable, no MJPEG parsing)
  SNAP_URL="${SNAP_URL:-http://127.0.0.1:8081/snapshot.jpg}"

  ok=0
  for _ in 1 2; do
    if curl_err="$(curl -fsS --max-time 4 "$SNAP_URL" -o "${JPEG_PATH}.tmp" 2>&1)"; then
      ok=1
      break
    fi
    sleep 0.2
  done

  if [[ "$ok" -eq 1 ]] && mv -f "${JPEG_PATH}.tmp" "$JPEG_PATH"; then

    if "$SCRIPT_DIR/pc_upload_snapshot.py" --jpeg "$JPEG_PATH" --token "$PC_TOKEN" --fingerprint "$PC_FINGERPRINT" >/dev/null 2>&1; then
      _successes_since_log=$((_successes_since_log + 1))
      now="$(date +%s)"
      if [ "$_last_success_log" -eq 0 ] || [ $((now - _last_success_log)) -ge "$SUCCESS_LOG_INTERVAL" ]; then
        log "Success — uploaded snapshots in last ${SUCCESS_LOG_INTERVAL}s: ${_successes_since_log}"
        _successes_since_log=0
        _last_success_log="$now"
      fi


      # Success: reset backoff
      backoff=0
      sleep "$INTERVAL_SECONDS"
      continue
    else
      echo "Uploader error: ${out}" >&2
    fi
  fi

  # Failure path: increase backoff conservatively
  if [[ "$backoff" -eq 0 ]]; then
    backoff="$INTERVAL_SECONDS"
  else
    backoff=$((backoff * 2))
    if [[ "$backoff" -gt "$max_backoff" ]]; then
      backoff="$max_backoff"
    fi
  fi

  sleep_time=$((backoff + jitter))
  echo "Snapshot/upload failed; backing off for ${sleep_time}s" >&2
  sleep "$sleep_time"
done
