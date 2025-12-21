# Troubleshooting

This project provides a read-only nginx proxy to Moonraker (default port `7126`).
If something breaks, the steps below help you quickly identify and fix it.

---

## Quick health checks

### Check nginx config is valid
```bash
sudo nginx -t
```

### Reload nginx after changes
```bash
sudo systemctl reload nginx
```

### Confirm the read-only proxy responds
```bash
curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1:7126/server/info
```

Expected: `200`

### Watch nginx traffic while testing MobileRaker
```bash
sudo tail -f /var/log/nginx/access.log
```

---

## MobileRaker shows printer info but live status/camera breaks

### Symptom
- MobileRaker can hit basic endpoints (like `/server/info`)
- The app can’t connect for live updates, and the camera/status may stop updating
- nginx access log shows repeated requests like:
  - `GET /websocket` returning `401`

### Cause
**HTTP Basic Auth (`auth_basic`) was enabled in nginx.**

MobileRaker (and other Moonraker clients) do **not** support HTTP Basic Authentication
for WebSocket connections. If auth is enabled, `/websocket` will return `401` and
the client will fail to connect.

### Fix
Edit your site file (example path below):

```bash
sudo nano /etc/nginx/sites-enabled/moonraker-readonly
```

Disable Basic Auth for the entire site by commenting these lines (or removing them):

```nginx
# auth_basic "Moonraker Read-Only";
# auth_basic_user_file /etc/nginx/.htpasswd;
```

Then:

```bash
sudo nginx -t
sudo systemctl reload nginx
```

### Confirm
From the nginx host:

```bash
curl -i http://127.0.0.1:7126/websocket
```

Expected:
- NOT `401 Unauthorized`
- You may see `400 Bad Request` with a message like:  
  `Can "Upgrade" only to "WebSocket".`  
  This is **normal** when using curl.

---

## `curl` to `/websocket` returns 400 “Upgrade only to WebSocket”

### Symptom
```bash
curl -i http://127.0.0.1:7126/websocket
```

Returns:
- `HTTP/1.1 400 Bad Request`
- `Can "Upgrade" only to "WebSocket".`

### Explanation
This is expected. `curl` is not performing a real WebSocket handshake unless you
manually provide the required Upgrade headers.

For troubleshooting, the key points are:
- `/websocket` should NOT ret
