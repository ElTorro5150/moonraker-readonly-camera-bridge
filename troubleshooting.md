# Troubleshooting

This project provides a read-only nginx proxy to Moonraker (default port `7126`).
If something breaks, the steps below help you quickly identify and fix it.

---

## Quick health checks

### Check nginx config is valid
```bash
sudo nginx -t
Reload nginx after changes
bash
Copy code
sudo systemctl reload nginx
Confirm the read-only proxy responds
bash
Copy code
curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1:7126/server/info
Expected: 200

Watch nginx traffic while testing MobileRaker
bash
Copy code
sudo tail -f /var/log/nginx/access.log
MobileRaker shows printer info but live status/camera breaks
Symptom
MobileRaker can hit basic endpoints (like /server/info)

But the app can’t connect for live updates, and the camera/status may stop updating

nginx access log shows repeated requests like:

GET /websocket returning 401

Cause
HTTP Basic Auth (auth_basic) was enabled in nginx.

MobileRaker (and other Moonraker clients) do not support HTTP Basic Authentication
for WebSocket connections. If auth is enabled, /websocket will return 401 and
the client will fail to connect.

Fix
Edit your site file (example path below):

bash
Copy code
sudo nano /etc/nginx/sites-enabled/moonraker-readonly
Disable Basic Auth for the entire site by commenting these lines (or removing them):

nginx
Copy code
# auth_basic "Moonraker Read-Only";
# auth_basic_user_file /etc/nginx/.htpasswd;
Then:

bash
Copy code
sudo nginx -t
sudo systemctl reload nginx
Confirm
From the nginx host:

bash
Copy code
curl -i http://127.0.0.1:7126/websocket
Expected:

NOT 401 Unauthorized

You may see 400 Bad Request with a message like:
Can "Upgrade" only to "WebSocket".
That is NORMAL with curl (see next section).

curl to /websocket returns 400 “Upgrade only to WebSocket”
Symptom
bash
Copy code
curl -i http://127.0.0.1:7126/websocket
Returns:

HTTP/1.1 400 Bad Request

Can "Upgrade" only to "WebSocket".

Explanation
This is expected. curl is not performing a real WebSocket handshake unless you
manually provide the Upgrade headers.

For troubleshooting, the key is simply:

/websocket should NOT return 401

MobileRaker should show a 101 for /websocket in nginx access logs when connected

Random behavior / “conflicting server name” / wrong site seems to load
Symptom
nginx warns about server name conflicts (often on port 7126)

Requests behave inconsistently

You have more than one server block listening on the same port

Common cause: backup files accidentally enabled
nginx loads all files in:

/etc/nginx/sites-enabled/*

If you leave backup copies (for example moonraker-readonly.bak) in sites-enabled,
nginx will load them too, and you may end up with multiple active server blocks.

Fix
List matching files:

bash
Copy code
ls -la /etc/nginx/sites-enabled/ | grep moonraker-readonly
Remove any unintended duplicates (example):

bash
Copy code
sudo rm /etc/nginx/sites-enabled/moonraker-readonly.bak
Then:

bash
Copy code
sudo nginx -t
sudo systemctl reload nginx
“It worked yesterday, now it doesn’t” after an update
Recommended approach
Check logs while reproducing the issue:

bash
Copy code
sudo tail -f /var/log/nginx/access.log
Look for non-200 responses:

bash
Copy code
sudo awk '$9 != 200 {print}' /var/log/nginx/access.log | tail -n 50
Validate nginx config and reload:

bash
Copy code
sudo nginx -t
sudo systemctl reload nginx
If MobileRaker isn’t connecting, focus on:

/websocket responses (should be 101 when connected)

any 401 responses (usually auth-related)

any unexpected new paths (may require allowlist additions)

Useful commands
Show which configs nginx is actually loading
bash
Copy code
sudo nginx -T | less
Find which server blocks listen on port 7126
bash
Copy code
sudo nginx -T | grep -n "listen .*7126"
Confirm the read-only site file is enabled
bash
Copy code
ls -la /etc/nginx/sites-enabled/ | grep moonraker-readonly
pgsql
Copy code

If you want, I can also give you the **exact git commands** to add and commit this file in the repo with mi
