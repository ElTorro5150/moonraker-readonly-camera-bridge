# moonraker-readonly-camera-bridge

**Safe, read-only Moonraker + Klipper bridge for camera-only Raspberry Pi hosts**

This project enables **MobileRaker** and other Moonraker-compatible clients to connect
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
- Exposes **read-only Moonraker APIs** via an **NGINX reverse proxy**
- Allows camera streaming and printer status visibility
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

### WebSocket Authentication Caveat

Moonraker clients (including **MobileRaker**) do **not** support HTTP Basic Authentication
for WebSocket connections.

If `auth_basic` is enabled in nginx, `/websocket` will return HTTP 401 and clients
will fail to connect.

For LAN-only setups, it is recommended to:
- Disable `auth_basic`
- Use a deny-by-default allowlist
- Restrict to GET/HEAD methods only
- Bind or firewall the port to the local network

### Nginx `sites-enabled/` Gotcha

⚠️ Nginx loads **all files** in `sites-enabled/`.  
Do **not** leave backup files (for example `.bak`) in this directory, or you may end up
with multiple active server blocks.

---

## 📦 Installation (Step-by-Step)

These instructions assume:
- You are running Linux (Debian/Ubuntu/Raspberry Pi OS)
- `nginx`, `moonraker`, and `klipper` are already installed and working
- You are **not** exposing this service to the public internet

> ⚠️ This project does **NOT** replace `/etc/nginx/nginx.conf`.  
> It installs **one nginx site file only**.

---

### 1️⃣ Clone the repository

```bash
cd ~
git clone https://github.com/<YOUR_GITHUB_USERNAME>/moonraker-readonly-camera-bridge.git
cd moonraker-readonly-camera-bridge
```

---

### 2️⃣ Install the nginx site configuration

Copy the provided nginx site file into the system nginx directory:

```bash
sudo cp nginx/moonraker-readonly.conf /etc/nginx/sites-available/moonraker-readonly
```

Enable the site:

```bash
sudo ln -s /etc/nginx/sites-available/moonraker-readonly /etc/nginx/sites-enabled/
```

---

### 3️⃣ Test the nginx configuration

```bash
sudo nginx -t
```

You should see:

```
syntax is ok
test is successful
```

If you see an error, **do not continue** until it is resolved.

---

### 4️⃣ Reload nginx

```bash
sudo systemctl reload nginx
```

---

### 5️⃣ Verify the read-only proxy

From the same machine, run:

```bash
curl http://127.0.0.1:7126/server/info
```

You should receive a JSON response from Moonraker.

---

## 📱 Client Configuration (MobileRaker)

In **MobileRaker**:

- Host / IP: `IP_OF_CAMERA_PI`
- Port: `7126`
- Protocol: `http`
- Authentication: **disabled**

Once connected, you should see:
- Printer status
- Webcam stream
- No ability to send commands or move the printer

---

## ✅ Security Model Summary

This setup is secured by:
- Deny-by-default nginx allowlist
- Read-only Moonraker endpoints
- GET/HEAD method enforcement
- No WebSocket authentication (required for MobileRaker)
- Intended LAN-only usage

---

## 🧹 Updating or Removing

To disable the proxy:

```bash
sudo rm /etc/nginx/sites-enabled/moonraker-readonly
sudo systemctl reload nginx
```

To remove it completely:

```bash
sudo rm /etc/nginx/sites-available/moonraker-readonly
sudo systemctl reload nginx
```

---

## 📌 Final Notes

- Files in this GitHub repo do **not** automatically sync to your system
- Changes made on your Pi must be committed and pushed manually if you want them saved to GitHub
- This repository is intended as a **reference implementation**, not a live configuration mirror

---
