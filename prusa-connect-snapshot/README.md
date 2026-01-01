# Prusa Connect Snapshot Uploader (Add-On)

This directory adds **Prusa Connect snapshot support** to the existing
`moonraker-readonly-camera-bridge` project.

It is intentionally an **additive, adjacent component** — nothing from Phase 1
is modified or replaced.

---

## What this does

- Captures **single JPEG snapshots** from a local camera pipeline
- Uploads snapshots to **Prusa Connect** at a fixed interval (default: ~10s)
- Keeps **MobileRaker compatibility**
- Avoids camera contention (single camera owner)

This does **not** provide live video to Prusa Connect.
Prusa Connect snapshots are the intended and supported use case.

---

## Design goals (non-negotiable)

- LAN-only
- Single camera owner
- No Moonraker camera streaming
- Deny-by-default network exposure
- No authentication hacks
- No `ffmpeg` dependency for snapshots
- Predictable, curl-friendly snapshot capture

---

## Architecture overview

Camera
│
▼
`rpicam-vid` (MJPEG over TCP, port 9000)
│
▼
`mjpeg_http_server.py`
├── `/stream.mjpg`   (debug / optional)
└── `/snapshot.jpg`  (single JPEG, used by uploader)
│
▼
Prusa Connect Snapshot Uploader

### Key points

- `rpicam-vid` is the **only** process that owns the camera
- MJPEG is exposed internally over TCP (`127.0.0.1:9000`)
- A lightweight Python HTTP server exposes:
  - `/stream.mjpg` for debugging
  - `/snapshot.jpg` for **stable single-frame capture**
- The uploader fetches `/snapshot.jpg` and uploads it to Prusa Connect

---

## Why `/snapshot.jpg` exists

Prusa Connect requires **single JPEG uploads**, not MJPEG streams.

Instead of parsing MJPEG or invoking ffmpeg:
- the HTTP server extracts **exactly one frame**
- returns a valid JPEG
- closes the connection immediately

This provides:
- predictable behavior
- minimal surface area
- reliable uploads

---

## Installation (recommended: one command)

From the **repository root**, run:

```bash
sudo ./install.sh

