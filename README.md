# MoonBridge
*(moonraker-readonly-camera-bridge)*

![Install](https://img.shields.io/badge/install-one--command-success)
![Status](https://img.shields.io/badge/status-stable-brightgreen)
![Security](https://img.shields.io/badge/mode-read--only-blue)
![Platform](https://img.shields.io/badge/platform-Debian%2013%20%7C%20RPi-orange)
![Release](https://img.shields.io/github/v/tag/ElTorro5150/moonraker-readonly-camera-bridge)


**MoonBridge** is a safe, read-only Moonraker + Klipper bridge designed for
**camera-only Raspberry Pi hosts**.

### ✅ Tested Platforms

| Hardware              | OS                                      | Architecture | Status |
|-----------------------|------------------------------------------|--------------|--------|
| Raspberry Pi Zero 2 W | Raspberry Pi OS (Trixie) 64-bit Lite     | ARM64        | ✅ Tested |


It enables **MobileRaker** and other Moonraker-compatible clients to connect
to a Raspberry Pi **without exposing any printer control, motion, or mutation
capability**.

Typical use cases include:
- Dedicated camera-only Raspberry Pi systems
- Prusa XL external camera hosts
- Monitoring-only deployments
- Environments where write access to Klipper must be strictly prohibited

---

## 🔒 What This Project Does

- Runs **Klipper using the official Linux Host MCU mode**
- Satisfies Moonraker’s requirement for a connected MCU **without emulating hardware**
- Exposes **read-only Moonraker APIs** via an **NGINX reverse proxy**
- Allows camera streaming and printer status visibility
- Explicitly blocks all POST / mutation requests

---

## 🚪 What This Project Does NOT Do

- 😌 Does not emulate an STM32 or any physical MCU
- ❌ Does not fake Klipper firmware responses
- ❌ Toes not allow printer movement, heating, or firmware restarts
- ❌ Toes not modify Klipper or Moonraker source code

This solution uses **only officially supported Klipper functionality**.

---

## 📴 Phase 2: Prusa Connect Snapshots (Add-On)

This repo includes an optional Phase 2 add-on that provides:

- `/snapshot.jpg` via a local cached-frame MJPEG http server
- Stable snapshot proxying through nginx (:7126/snapshot.jpg)
- A systemd uploader that sends snapshots to Prusa Connect on an interval

See:
- `PHASE2-CHECKLIST.md`
- `prusa-connect-snapshot/README.md`

Stable milestone tag: `phase2-stable`

---

## 🧠 Installation

You can install MoonBridge in **recommended ways**:

- **Option A (Recommended): ** One-command installer** (menu-driven, safe defaults)
- **Option B:** Clone and launch menu manually)

---

## ✩ Option A — One-Command Installer (Recommended)

Run from any terminal:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/ElTorro5150/moonraker-readonly-camera-bridge/main/get-moonbridge.sh)"
```

---

## 🧠 Option B — Clone & Launch Manually

```bash
git clone https://github.com/ElTorro5150/moonraker-readonly-camera-bridge.git
cd moonraker-readonly-camera-bridge
./run-moonbridge.sh
```

---

## ✨ Option C — Direct System Installer (Advanced)

```bash
sudo ./install.sh
```

Use this only if you understand the implications.


EOF
