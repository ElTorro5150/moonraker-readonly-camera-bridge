prusa@PRUSA-XL-CAM:~ $ sudo cat /usr/local/bin/xl_cam_raw_mjpeg.sh
#!/usr/bin/env bash
exec rpicam-vid \
  -t 0 \
  --codec mjpeg \
  --width 1280 \
  --height 720 \
  --framerate 15 \
  --inline \
  --listen \
  -o tcp://127.0.0.1:9000
