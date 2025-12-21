# Architecture

This repository is a small, pragmatic set of configs and scripts that supports:
- Moonraker running locally on the host (default: 127.0.0.1:7125)
- An nginx reverse proxy that exposes a read-only interface (default: listen 7126 -> proxy to 7125)
- Camera bridge services/scripts for feeding MJPEG/HTTP endpoints (repo-specific)

## Components

### Moonraker (upstream)
Moonraker is the Klipper API server. It provides status endpoints as well as mutating endpoints (gcode/script/restart/etc.).

### Read-only proxy (nginx)
The read-only proxy exists to reduce risk by denying mutating HTTP methods. The current implementation is method-based:
- Allows: GET/HEAD
- Denies: everything else

This is implemented in `nginx/moonraker-readonly.conf`.

### Camera bridge scripts/services
The repo includes scripts and systemd units intended to expose camera feeds in a predictable way.
Exact wiring depends on your host/printer environment, but the layout is:
- `scripts/`  : helper scripts used by services
- `systemd/`  : unit files intended to be installed into systemd

## Ports (defaults)
- Moonraker: 7125 (loopback)
- Read-only nginx: 7126 (LAN-facing or loopback, depending on your nginx bind/firewall)

## Security notes
- Method-based blocking is simple and effective against most accidental writes, but it is not a complete security model.
- If you need a stricter model, we can move to an allowlist of specific Moonraker endpoints.
