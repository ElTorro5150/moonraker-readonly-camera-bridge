#!/usr/bin/env bash
set -euo pipefail

while true; do
  rpicam-vid \
    -t 0 \
    --codec mjpeg \
    --width 1280 \
    --height 720 \
    --framerate 15 \
    --inline \
    --listen \
    -o tcp://127.0.0.1:9000 || true

  # If the client disconnects and rpicam-vid aborts (SIGPIPE/ABRT), restart cleanly.
  echo "$(date -Iseconds) xl_cam_raw_mjpeg.sh: rpicam-vid exited; restarting in 0.2s" >&2
  sleep 0.2
done
