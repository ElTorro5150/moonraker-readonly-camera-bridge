# moonraker-readonly-camera-bridge

This repository contains configuration and scripts used to provide **read-only**
access to Moonraker and camera feeds.

## Read-only Moonraker proxy (nginx)

An nginx reverse proxy listens on port **7126** and forwards requests to Moonraker
on **127.0.0.1:7125** while allowing only `GET` and `HEAD` requests.
All mutating requests are denied.

WebSocket headers are enabled so read-only clients can subscribe to printer
status updates.

See:
- `nginx/moonraker-readonly.conf`

## Verification

Run the verification script from the repo root:

```bash
./scripts/verify.sh
```

Default endpoints:
- Moonraker: `http://127.0.0.1:7125`
- Read-only proxy: `http://127.0.0.1:7126`
