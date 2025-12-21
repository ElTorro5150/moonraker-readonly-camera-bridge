# moonraker-readonly-camera-bridge

**Safe, read-only Moonraker + Klipper bridge for camera-only Raspberry Pi hosts**

This project enables Mobileraker and other Moonraker-compatible clients to connect
to a Raspberry Pi **without exposing any printer control or motion capability**.

It is designed for use cases such as:
- Dedicated camera-only Raspberry Pi systems
- Prusa XL external camera hosts
- Monitoring-only deployments
- Environments where write access to Klipper must be strictly prohibited

---

## 🔒 What This Project Does

- Runs **Klipper using the official Linux Host MCU mode**
- Satisfies Moonraker’s requirement for a connected MCU **without emulating hardware**
- Exposes **read-only Moonraker APIs** via an NGINX reverse proxy
- Allows camera streaming and status visibility
- Explicitly blocks all POST / mutation requests

---

## 🚫 What This Project Does NOT Do

- ❌ Does not emulate an STM32 or any physical MCU
- ❌ Does not fake Klipper firmware responses
- ❌ Does not allow printer movement, heating, or firmware restarts
- ❌ Does not modify Klipper or Moonraker source code

This solution uses **only officially supported Klipper functionality**.

---

## 🧠 Architecture Overview

## WebSocket Authentication Caveat

Moonraker clients (including MobileRaker) do not support
HTTP Basic Authentication for WebSocket connections.

If `auth_basic` is enabled in nginx, `/websocket` will return
HTTP 401 and clients will fail to connect.

For LAN-only setups, it is recommended to:
- Disable `auth_basic`
- Use a deny-by-default allowlist
- Restrict to GET/HEAD methods only
- Bind or firewall the port to the local network
