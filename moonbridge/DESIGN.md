# MoonBridge (Installer Frontend) — Design Spec

Repository: moonraker-readonly-camera-bridge  
Goal: Provide a simple, menu-driven installer frontend (KIAUH-style UX) WITHOUT forking KIAUH.

## Scope (hard limits)
MoonBridge installs ONLY these three modes:

1) **MobileRaker Streaming Only**
   - MJPEG stream
   - nginx read-only proxy
   - MobileRaker compatibility endpoints (as currently implemented in this repo)

2) **Prusa Connect Snapshots Only**
   - Snapshot uploader service
   - No live streaming
   - No MobileRaker-specific config

3) **Full Install**
   - Streaming + nginx + Prusa Connect snapshots

No feature creep beyond these modes.

## Source-of-truth in this repo (important)
MoonBridge will install from these paths:

### Streaming components (source-of-truth)
- systemd:
  - systemd/xl-cam-feed.service
  - systemd/xl-cam-http.service
- scripts:
  - scripts/xl_cam_raw_mjpeg.sh
  - scripts/mjpeg_http_server.py
- nginx:
  - nginx/moonraker-readonly.conf

### Prusa snapshots components (source-of-truth)
- systemd:
  - systemd/prusa-connect-snapshot.service
- component:
  - prusa-connect-snapshot/ (scripts + env example + README)

### Host MCU / core stack artifacts (source-of-truth)
- deploy/systemd/klipper-host-mcu.service
- deploy/systemd/overrides/klipper-host-mcu.service.d/override.conf
- deploy/config_examples/*

NOTE: The repo contains older/duplicate paths (e.g., phase2/ and deploy/nginx/). MoonBridge intentionally ignores these to avoid ambiguity.

## Install locations (conventional + predictable)
- Scripts:
  - /usr/local/bin/ (e.g., moonbridge-managed helpers)
- Python scripts:
  - /usr/local/lib/moonbridge/ (optional) or /usr/local/bin/ if executable
- systemd units:
  - /etc/systemd/system/
- nginx site:
  - /etc/nginx/sites-available/moonbridge
  - /etc/nginx/sites-enabled/moonbridge -> sites-available/moonbridge
- config/state:
  - /etc/moonbridge/
  - /var/lib/moonbridge/ (optional for state flags)

Prusa Connect secrets:
- env file is created OUTSIDE the repo, e.g.:
  - /etc/prusa-connect-snapshot/prusa-connect.env
- permissions: root:root 600 (or owner set to the service user)
- MoonBridge never writes tokens into git, never commits, never prints secrets.

## Idempotency rules (boring on purpose)
- If target file exists and is identical: print "unchanged"
- If target exists and differs:
  - backup once with timestamp suffix: .bak-YYYYMMDD-HHMMSS
  - replace with repo version
- systemd:
  - daemon-reload when any unit changes
  - enable/start actions are repeatable
- nginx:
  - always `nginx -t` before reload
  - reload only if config test passes

## Menu structure (whiptail)
Main Menu:
- Install: MobileRaker Streaming Only
- Install: Prusa Connect Snapshots Only
- Install: Full Install
- Status / Health Check
- Uninstall (explicit)
- Exit

## Verification checks (end of install)
Streaming:
- systemctl status xl-cam-feed.service
- systemctl status xl-cam-http.service
- local curl check:
  - curl -I http://127.0.0.1:8081/snapshot.jpg (if applicable)
  - curl -I http://127.0.0.1:8081/stream.mjpg (or nginx endpoint you expose)

nginx:
- nginx -t
- systemctl reload nginx
- curl -I http://127.0.0.1:7126/stream.mjpg (or configured endpoint)

Prusa snapshots:
- env file exists at /etc/prusa-connect-snapshot/prusa-connect.env
- service enabled
- service either running (if env filled) or cleanly stopped with clear instructions

## "Done" criteria
- A new user can clone repo, run MoonBridge, choose one of 3 modes, and get a working setup.
- Re-running MoonBridge does not break a working system.
- No secrets are stored in the repo or printed to the terminal.
