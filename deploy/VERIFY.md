# Verify (expected working endpoints)

Assumptions:
- nginx listens on :7126
- Moonraker listens on 127.0.0.1:7125
- MJPEG HTTP server on 127.0.0.1:8081

Run:

curl -sS http://127.0.0.1:7126/server/info ; echo
curl -sS http://127.0.0.1:7126/webcam/?action=snapshot -o /dev/null -D- | head
curl -sS -L --max-time 2 http://127.0.0.1:7126/webcam/?action=stream -o /dev/null -D- | head

Expected:
- /server/info returns JSON
- /webcam/?action=snapshot returns 307 -> /webcam/snapshot then image/jpeg
- /webcam/?action=stream returns 307 -> /webcam/stream then multipart/x-mixed-replace

Notes:
- This repo is intended to be read-only and safe to expose via reverse proxy / VPN.
