# Phase 2 – Snapshot & MJPEG Bridge Completion Checklist

This checklist documents the **completed, working state** of Phase 2 for
`moonraker-readonly-camera-bridge`.

---

## Goals (All Met)

- LAN-only operation
- Deny-by-default network exposure
- No Moonraker camera ownership
- Single camera owner at all times
- MobileRaker compatibility
- Stable Prusa Connect snapshot uploads
- No MJPEG parsing in Prusa Connect path
- No ffmpeg dependency for snapshots
- No secrets committed to git

---
## Snapshot Stability Model (Important)

`mjpeg_http_server.py` maintains **a single persistent TCP connection**
to the MJPEG source (`127.0.0.1:9000`) and continuously caches the most
recent complete JPEG frame in memory.

- `/snapshot.jpg` returns the **cached frame** immediately
- `/stream.mjpg` streams cached frames without opening new TCP connections
- No endpoint ever opens a second connection to the camera feed

This design:
- Prevents camera / TCP contention
- Eliminates snapshot flapping (200/503 behavior)
- Allows simultaneous use by:
  - MobileRaker
  - nginx
  - Prusa Connect snapshot uploader

## Network Architecture

Camera
│
▼
`rpicam-vid` (MJPEG over TCP, `127.0.0.1:9000`)
│
▼
`mjpeg_http_server.py`
├── `/stream.mjpg`   (optional/debug, MobileRaker)
└── `/snapshot.jpg`  (single JPEG frame)
│
▼
Prusa Connect Snapshot Uploader

---

## Key Endpoints

| Purpose | Endpoint | Target |
|------|--------|--------|
| MobileRaker MJPEG | `/stream.mjpg` | `http://127.0.0.1:8081/stream.mjpg` |
| Snapshot capture | `/snapshot.jpg` | `http://127.0.0.1:8081/snapshot.jpg` |

---

## Services

### xl-cam-http.service
- Runs `mjpeg_http_server.py`
- Exposes HTTP endpoints only on localhost
- Restart always

### prusa-connect-snapshot.service
- Pulls `/snapshot.jpg`
- Uploads single JPEG frames to Prusa Connect
- No MJPEG parsing
- No camera access

---

## Security & Safety

- No auth bypasses
- No new public ports
- Nginx allowlist enforced
- Real env files ignored by git
- Only `*.env.example` files tracked

---

## Files Added (Phase 2)

- `phase2/nginx/moonraker-readonly`
- `phase2/bin/mjpeg_http_server.py`
- `phase2/prusa-connect-snapshot/pc_run_loop.sh`
- `phase2/prusa-connect-snapshot/prusa-connect.env.example`
- `phase2/systemd/xl-cam-http.service`
- `phase2/systemd/prusa-connect-snapshot.service`

---

## Non-Goals (Explicit)

- Live video in Prusa Connect
- Camera ownership by Moonraker
- Multiple camera consumers
- Cloud exposure

---

## Phase 2 Status

**COMPLETE – STABLE – DEPLOYED**

