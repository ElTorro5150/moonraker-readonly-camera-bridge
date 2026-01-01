#!/usr/bin/env python3
import socket
import time
import threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

TCP_HOST = "127.0.0.1"
TCP_PORT = 9000
HTTP_HOST = "127.0.0.1"
HTTP_PORT = 8081
BOUNDARY = "frame"

SOI = b"\xff\xd8"
EOI = b"\xff\xd9"

_latest_jpeg = None
_latest_ts = 0.0
_lock = threading.Lock()
def _reader_loop():
    global _latest_jpeg, _latest_ts
    backoff = 0.2
    while True:
        try:
            s = socket.create_connection((TCP_HOST, TCP_PORT), timeout=3.0)
            s.settimeout(3.0)
            buf = bytearray()
            started = False

            while True:
                chunk = s.recv(65536)
                if not chunk:
                    raise ConnectionError("TCP feed closed")
                buf.extend(chunk)

                if not started:
                    i = buf.find(SOI)
                    if i >= 0:
                        if i > 0:
                            del buf[:i]
                        started = True
                    else:
                        if len(buf) > 2_000_000:
                            del buf[:-2]
                        continue

                j = buf.find(EOI)
                if j >= 0:
                    frame = bytes(buf[: j + 2])
                    del buf[: j + 2]
                    started = False
                    with _lock:
                        _latest_jpeg = frame
                        _latest_ts = time.time()
        except Exception:
            try:
                s.close()
            except Exception:
                pass
            time.sleep(backoff)
            backoff = min(backoff * 1.5, 2.0)

class Handler(BaseHTTPRequestHandler):
    server_version = "mjpeg_http_server/3.0"

    def log_message(self, fmt, *args):
        return

    def do_GET(self):
        if self.path in ("/", "/stream.mjpg"):
            return self.handle_stream()
        if self.path == "/snapshot.jpg":
            return self.handle_snapshot()
        self.send_response(404)
        self.end_headers()

    def _get_latest(self):
        with _lock:
            return _latest_jpeg, _latest_ts

    def handle_snapshot(self):
        jpg, ts = self._get_latest()
        if not jpg:
            self.send_response(503)
            self.send_header("Cache-Control", "no-cache")
            self.send_header("Pragma", "no-cache")
            self.end_headers()
            return

        self.send_response(200)
        self.send_header("Cache-Control", "no-cache")
        self.send_header("Pragma", "no-cache")
        self.send_header("Content-Type", "image/jpeg")
        self.send_header("Content-Length", str(len(jpg)))
        self.end_headers()
        try:
            self.wfile.write(jpg)
        except BrokenPipeError:
            pass
    def handle_stream(self):
        self.send_response(200)
        self.send_header("Cache-Control", "no-cache")
        self.send_header("Pragma", "no-cache")
        self.send_header("Content-Type", f"multipart/x-mixed-replace; boundary={BOUNDARY}")
        self.end_headers()

        last_ts = 0.0
        while True:
            jpg, ts = self._get_latest()
            if not jpg or ts == last_ts:
                time.sleep(0.05)
                continue
            last_ts = ts
            try:
                header = (
                    f"--{BOUNDARY}\r\n"
                    "Content-Type: image/jpeg\r\n"
                    f"Content-Length: {len(jpg)}\r\n"
                    "\r\n"
                ).encode("ascii")
                self.wfile.write(header)
                self.wfile.write(jpg)
                self.wfile.write(b"\r\n")
                self.wfile.flush()
            except (BrokenPipeError, ConnectionResetError):
                return

def main():
    t = threading.Thread(target=_reader_loop, daemon=True)
    t.start()
    httpd = ThreadingHTTPServer((HTTP_HOST, HTTP_PORT), Handler)
    print(f"HTTP server listening on http://{HTTP_HOST}:{HTTP_PORT} (tcp source {TCP_HOST}:{TCP_PORT})")
    httpd.serve_forever()

if __name__ == "__main__":
    main()
