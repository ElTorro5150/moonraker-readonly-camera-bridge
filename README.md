# moonraker-readonly-camera-bridge

**Safe, read-only Moonraker + Klipper bridge for camera-only Raspberry Pi hosts**

This project enables **MobileRaker** and other Moonraker-compatible clients to connect
to a Raspberry Pi **without exposing any printer control or motion capability**.

Id is designed for use cases such as:
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

## What's New (v1.2.4)

- Installer menu now includes **Set Snapshot Upload Interval** for Prusa Connect snapshots (updates `INTERVAL_SECONDS` in `/etc/prusa-connect-snapshot/prusa-connect.env` and restarts the snapshot service).
- Interval **minimum is 5 seconds** (power-user option). When set under **15 seconds**, the installer shows a warning that it may increase CPU/bandwidth and could be rate-limited; restarting the service may take a few seconds on Raspberry Pi.

