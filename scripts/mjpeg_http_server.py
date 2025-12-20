#!/usr/bin/env python3
import socket
from http.server import BaseHTTPRequestHandler, HTTPServer

TCP_HOST = "127.0.0.1"
TCP_PORT = 9000
HTTP_PORT = 8081
BOUNDARY = "frame"

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
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

        sock = socket.create_connection((TCP_HOST, TCP_PORT))
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
