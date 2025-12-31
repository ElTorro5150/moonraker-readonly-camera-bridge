# Prusa Connect Snapshot Uploader (Add-On)

This directory adds **snapshot uploads to Prusa Connect** on top of the existing
`moonraker-readonly-camera-bridge` project.

This is an **additive component**:
- It does NOT modify the existing Moonraker bridge
- It does NOT stream live video to Prusa Connect
- It does NOT allow Moonraker to access the camera
- It keeps a single camera owner at all times

Snapshots are uploaded to Prusa Connect at a fixed interval (default: ~10 seconds).

---

## Design goals

- LAN-only
- No camera contention (single camera owner)
- No Moonraker camera streaming
- MobileRaker-compatible
- Minimal dependencies
- Predictable behavior
- Easy install / uninstall

---

## Architecture overview

Camera
  -> rpicam-vid (MJPEG over TCP, port 9000)
  -> mjpeg_http_server.py
       - /stream.mjpg   (debug MJPEG stream)
       - /snapshot.jpg  (single-frame JPEG endpoint)
  -> Prusa Connect Snapshot Uploader (uploads JPEG to Prusa Connect)

Notes:
- `/snapshot.jpg` returns **one JPEG frame and closes**
- Prusa Connect only receives snapshots (no live video)
- No ffmpeg, no MJPEG parsing

---

## Installation

```bash
git clone https://github.com/ElTorro5150/moonraker-readonly-camera-bridge.git
cd moonraker-readonly-camera-bridge/prusa-connect-snapshot
sudo ./install.sh

eof
