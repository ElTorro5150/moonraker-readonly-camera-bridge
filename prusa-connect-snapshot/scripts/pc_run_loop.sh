#!/usr/bin/env bash
set -euo pipefail

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
set +a

: "${PC_TOKEN:?missing PC_TOKEN}"
: "${PC_FINGERPRINT:?missing PC_FINGERPRINT}"
: "${MJPEG_URL:?missing MJPEG_URL}"
: "${INTERVAL_SECONDS:?missing INTERVAL_SECONDS}"
: "${JPEG_PATH:?missing JPEG_PATH}"

# Ensure runtime dir exists (systemd will also handle this later)
RUNDIR="$(dirname "$JPEG_PATH")"
mkdir -p "$RUNDIR"

# Simple backoff on failures (seconds)
backoff=0
max_backoff=300  # 5 minutes

while true; do
  # Small jitter to avoid perfectly regular spikes (0-1s)
  jitter=$((RANDOM % 2))

  if "$SCRIPT_DIR/pc_capture_one_frame.py" --url "$MJPEG_URL" --out "$JPEG_PATH" --timeout 3 >/dev/null 2>&1; then
   if "$SCRIPT_DIR/pc_upload_snapshot.py" --jpeg "$JPEG_PATH" --token "$PC_TOKEN" --fingerprint "$PC_FINGERPRINT" >/dev/null 2>&1; then
  echo "Uploaded snapshot to Prusa Connect"

      # Success: reset backoff
      backoff=0
      sleep "$INTERVAL_SECONDS"
      continue
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
