#!/usr/bin/env python3
import socket
from http.server import BaseHTTPRequestHandler, HTTPServer

TCP_HOST = "127.0.0.1"
TCP_PORT = 9000
HTTP_PORT = 8081
BOUNDARY = "frame"

SNAPSHOT_TIMEOUT_SEC = 2.0  # fail fast if feed is stalled

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
	        # ---- NEW: single-frame endpoint ----
        if self.path in ("/snapshot.jpg", "/snapshot"):
            buffer = b""
            sock = None

            try:
                sock = socket.create_connection((TCP_HOST, TCP_PORT), timeout=SNAPSHOT_TIMEOUT_SEC)
                sock.settimeout(SNAPSHOT_TIMEOUT_SEC)

                # Read until we find one complete JPEG (FFD8 ... FFD9)
                while True:
                    buffer += sock.recv(65536)

                    start = buffer.find(b"\xff\xd8")
                    end = buffer.find(b"\xff\xd9", start + 2) if start != -1 else -1

                    if start != -1 and end != -1:
                        jpg = buffer[start:end + 2]

                        self.send_response(200)
                        self.send_header("Cache-Control", "no-cache")
                        self.send_header("Pragma", "no-cache")
                        self.send_header("Content-Type", "image/jpeg")
                        self.send_header("Content-Length", str(len(jpg)))
                        self.end_headers()

                        self.wfile.write(jpg)
                        return

            except ConnectionRefusedError:
                # Feed not up / not accepting connections
                self.send_response(503)
                self.end_headers()
                return
            except Exception:
                # Timeout or other read error
                self.send_response(504)
                self.end_headers()
                return
            finally:
                if sock is not None:
                    sock.close()


        # ---- EXISTING: MJPEG stream endpoints (unchanged behavior) ----
        if self.path not in ("/", "/stream.mjpg"):
            self.send_response(404)
            self.end_headers()
            return

        self.send_response(200)
        self.send_header("Cache-Control", "no-cache")
        self.send_header("Pragma", "no-cache")
        self.send_header(
            "Content-Type",
            f"multipart/x-mixed-replace; boundary={BOUNDARY}"
        )
        self.end_headers()

        try:
            sock = socket.create_connection((TCP_HOST, TCP_PORT), timeout=2.0)
            sock.settimeout(2.0)
        except Exception:
            # Feed not available; fail cleanly instead of crashing the handler
            self.send_response(503)
            self.end_headers()
            return

        buffer = b""

        try:
            while True:
                buffer += sock.recv(65536)
                while True:
                    start = buffer.find(b"\xff\xd8")
                    end = buffer.find(b"\xff\xd9", start + 2)
                    if start == -1 or end == -1:
                        break
                    jpg = buffer[start:end+2]
                    buffer = buffer[end+2:]

                    self.wfile.write(
                        f"--{BOUNDARY}\r\n"
                        f"Content-Type: image/jpeg\r\n"
                        f"Content-Length: {len(jpg)}\r\n\r\n".encode()
                        + jpg + b"\r\n"
                    )
        except Exception:
            pass
        finally:
            sock.close()

HTTPServer(("0.0.0.0", HTTP_PORT), Handler).serve_forever()
