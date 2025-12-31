#!/usr/bin/env python3
"""
pc_upload_snapshot.py

Uploads a JPEG snapshot to Prusa Connect Camera API.

Uses:
  - Token header
  - Fingerprint header
Uploads to:
  https://connect.prusa3d.com/c/snapshot

Docs:
  Prusa Connect Camera API (OpenAPI / docs)
"""

import argparse
import os
import sys
import urllib.request


DEFAULT_ENDPOINT = "https://connect.prusa3d.com/c/snapshot"


def read_file_bytes(path: str) -> bytes:
    with open(path, "rb") as f:
        return f.read()


def upload_snapshot(endpoint: str, token: str, fingerprint: str, jpeg_bytes: bytes, timeout_s: float) -> int:
    req = urllib.request.Request(endpoint, method="PUT", data=jpeg_bytes)
    req.add_header("Token", token)
    req.add_header("Fingerprint", fingerprint)
    req.add_header("Content-Type", "image/jpeg")
    req.add_header("Content-Length", str(len(jpeg_bytes)))

    try:
        with urllib.request.urlopen(req, timeout=timeout_s) as resp:
            # Return HTTP status (e.g., 200, 201, 204 depending on API behavior)
            return resp.status
    except urllib.error.HTTPError as e:
        # HTTPError is also a valid response with status code
        return e.code


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--jpeg", required=True, help="Path to JPEG file (e.g. /run/prusa-connect/latest.jpg)")
    ap.add_argument("--token", required=True, help="Prusa Connect camera token")
    ap.add_argument("--fingerprint", required=True, help="Stable camera fingerprint")
    ap.add_argument("--endpoint", default=DEFAULT_ENDPOINT, help=f"Upload endpoint (default: {DEFAULT_ENDPOINT})")
    ap.add_argument("--timeout", type=float, default=10.0, help="HTTPS timeout seconds (default: 10)")
    args = ap.parse_args()

    if not os.path.isfile(args.jpeg):
        print(f"ERROR: JPEG file does not exist: {args.jpeg}", file=sys.stderr)
        return 2

    jpeg_bytes = read_file_bytes(args.jpeg)

    # Basic sanity checks
    if len(jpeg_bytes) < 1000:
        print("ERROR: JPEG file is unexpectedly small; refusing to upload", file=sys.stderr)
        return 2
    if not (jpeg_bytes.startswith(b"\xff\xd8") and jpeg_bytes.endswith(b"\xff\xd9")):
        print("ERROR: File does not look like a complete JPEG (missing SOI/EOI markers)", file=sys.stderr)
        return 2

    status = upload_snapshot(args.endpoint, args.token, args.fingerprint, jpeg_bytes, args.timeout)

    if 200 <= status < 300:
        print(f"Upload OK (HTTP {status})")
        return 0

    print(f"Upload FAILED (HTTP {status})", file=sys.stderr)
    return 3


if __name__ == "__main__":
    raise SystemExit(main())
