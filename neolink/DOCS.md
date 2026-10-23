# Neolink (Reolink battery & 4G cameras)

A bridge for Reolink cameras that the Home Assistant Reolink integration does not support: battery
cameras without a Home Hub and 4G LTE cameras (the Go series). The app runs a fork of
[Neolink](https://github.com/QuantumEntangledAndy/neolink) with a WebSocket API (`ws-rtsp` mode).
Entities are created by the **Neolink** integration from
[home-assistant-neolink-integration](https://github.com/witold-gren/home-assistant-neolink-integration) —
no MQTT needed.

- After starting, the app announces itself to the Supervisor: Home Assistant shows a discovered
  Neolink integration.
- **RTSP**: `rtsp://ha:<password>@<HA address>:8564/<name>/sub`; the password is in
  `/data/rtsp_password` (the integration receives it in the announcement).
- **WebSocket API**: port 3002, only inside the HA network (you can publish it in the Network panel);
  the token is in `/data/ws_token`.
- The fork is compiled from source while the app is installed (a few minutes on a PC, much longer on
  a Raspberry Pi).

Tested with a Reolink Go Plus / Go G330 (firmware v3.0.0.662) over 4G.

## Configuration
```yaml
cameras:
  - name: Garden          # letters, digits, _ (part of the RTSP path)
    uid: 95270000ABCDEFGH  # 16 characters, starts with 9527 (Reolink app → device info)
    username: admin
    password: "…"         # the DEVICE password set in the Reolink app
    discovery: cellular   # cellular for 4G cameras; relay / map / remote / local
    stream: subStream     # subStream saves data; mainStream / both
    idle_disconnect: true
```

## 4G camera: data and battery
- `discovery: cellular` — connects only through Reolink's servers.
- `stream: subStream` — about 110 kbit/s (0.8 MB per minute of viewing).
- `idle_disconnect: true` — disconnects 30 s after the last use; a picture or a command wakes the
  camera (first picture after about 15 s).
- `battery_minutes` — reads the battery only while connected, never wakes the camera.
- `push: true` — motion from Reolink push notifications (Firebase). The camera reports PIR detections
  even while it sleeps; the motion sensor in HA stays on for `motion_seconds` (default 30 s). Turning
  PIR off in the camera (the "PIR sensor" switch) silences the notifications too.
- `motion: false` — extra motion listening while the camera is connected; enable deliberately.

## Password
`password` is the **device** password set in the Reolink app, often different from the account
password. A few failed logins can lock the camera for a while.

## Troubleshooting
`log_level: debug` writes details from Neolink itself to the log, including the content of every
Reolink push notification (the `push payload: ...` line right after `push notification (motion)`).
Network libraries and the camera protocol stay at `info`. Go back to `info` afterwards.

## The fork
What the patches add and the WebSocket protocol: [FORK.md](FORK.md).
