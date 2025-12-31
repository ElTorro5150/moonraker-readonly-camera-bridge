#!/usr/bin/env python3
"""
pc_capture_one_frame.py

Connects to an MJPEG HTTP stream (multipart/x-mixed-replace) and extracts exactly
one JPEG frame by scanning for JPEG start/end markers (FFD8 ... FFD9).

Writes atomically: <output>.tmp -> <output>

Usage:
  pc_capture_one_frame.py --url http://127.0.0.1:8081/ --out /run/prusa-connect/latest.jpg
"""

import argparse
import os
import sys
import time
import urllib.request

JPEG_SOI = b"\xff\xd8"  # Start Of Image
JPEG_EOI = b"\xff\xd9"  # End Of Image


def ensure_parent_dir(path: str) -> None:
    parent = os.path.dirname(path)
    if parent and not os.path.isdir(parent):
        os.makedirs(parent, exist_ok=True)


def capture_one_jpeg(url: str, timeout_s: float, max_bytes: int) -> bytes:
    # urllib.request is in the standard library (no extra installs).
    req = urllib.request.Request(url, method="GET")
    with urllib.request.urlopen(req, timeout=timeout_s) as resp:
        # Read in chunks until we find one full JPEG
        buf = bytearray()
        found_soi = False
        soi_index = -1

        start_time = time.time()
        while True:
            chunk = resp.read(4096)
            if not chunk:
                raise RuntimeError("Stream ended before a JPEG frame was captured")

            buf.extend(chunk)

            # Safety limits
            if len(buf) > max_bytes:
                raise RuntimeError(f"Exceeded max_bytes={max_bytes} without completing a JPEG frame")

            # Timeout safety (in addition to socket timeout)
            if (time.time() - start_time) > timeout_s:
                raise RuntimeError(f"Timed out after {timeout_s} seconds while capturing a JPEG frame")

            if not found_soi:
                soi_index = buf.find(JPEG_SOI)
                if soi_index != -1:
                    found_soi = True

            if found_soi:
                eoi_index = buf.find(JPEG_EOI, soi_index + 2)
                if eoi_index != -1:
                    # Include EOI marker bytes
                    jpeg = bytes(buf[soi_index : eoi_index + 2])
                    return jpeg


def atomic_write(path: str, data: bytes) -> None:
    ensure_parent_dir(path)
    tmp_path = path + ".tmp"
    with open(tmp_path, "wb") as f:
        f.write(data)
        f.flush()
        os.fsync(f.fileno())
    os.replace(tmp_path, path)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--url", required=True, help="MJPEG stream URL (e.g. http://127.0.0.1:8081/)")
    ap.add_argument("--out", required=True, help="Output JPEG path (e.g. /run/prusa-connect/latest.jpg)")
    ap.add_argument("--timeout", type=float, default=3.0, help="Capture timeout in seconds (default: 3)")
    ap.add_argument("--max-bytes", type=int, default=2_000_000, help="Max bytes to buffer before failing (default: 2,000,000)")
    args = ap.parse_args()

    try:
        jpeg = capture_one_jpeg(args.url, args.timeout, args.max_bytes)
        # Basic sanity: JPEG should start with SOI and end with EOI
        if not (jpeg.startswith(JPEG_SOI) and jpeg.endswith(JPEG_EOI)):
            raise RuntimeError("Captured data did not look like a complete JPEG")
        atomic_write(args.out, jpeg)
        print(f"Wrote {len(jpeg)} bytes to {args.out}")
        return 0
    except Exception as e:
        print(f"ERROR: {e}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
