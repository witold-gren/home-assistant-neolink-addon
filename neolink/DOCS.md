# Neolink (Reolink battery & 4G cameras)

🇵🇱 [Polska wersja](DOCS.pl.md)

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

## Recorded live views
Switch **Record live view** on for a camera in the Neolink integration. From then on every live view
of that camera is written, as it is watched and without transcoding, to Home Assistant's media folder:
`/media/neolink/<camera>/<YYYY-MM-DD>/HHMMSS-HHMMSS.mp4` (Media → My media → neolink). Nothing is
recorded while nobody watches, so it costs no extra data or battery. Old files stay until you switch
on `record_cleanup` (then those older than `record_keep_days` go once a day).

## SD card recordings
The recordings the camera makes on its SD card (on motion) can be copied to the same folder as the
recorded live views, `/media/neolink/<camera>/<YYYY-MM-DD>/HHMMSS-HHMMSS.mp4`, named by the
camera's own start and end of the event, so they show on the same timeline. The Neolink integration
has a **Sync recordings** button (the last 7 days: it compares the card with the folder and copies
what is missing) and the `neolink.sync_recordings` action (`hours`, `latest: true` for only the
newest one, e.g. a few minutes after a motion alert). The **Auto-copy recordings** switch of a
camera copies the newest recording 5 minutes after each motion alert by itself (off by default);
dashboards show the card's recordings and copy them by hand either way.

Every copy costs mobile data and keeps the camera awake: a 30 s recording of the main stream of a
Go Plus is about 13 MB and takes 2-3 minutes over 4G. `sd_stream: sub` copies the small stream
instead (a fraction of the data, 640×360). Files are written as `….mp4.part` and renamed once whole.

## Talking through the camera
The Neolink integration lets a dashboard (e.g. Home Dashboard) talk through the camera's speaker:
the microphone of the phone or tablet goes over Home Assistant to this app, which encodes it for the
camera. Talking wakes the camera; over 4G expect a delay of a second or two.

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

**The live view has no sound** — up to 0.1.0 the RTSP stream carried the sound as raw PCM, which Home
Assistant's HLS player drops and go2rtc had to transcode for WebRTC while the camera was still waking.
From 0.2.0 the sound comes as AAC and Opus. If there is still none, check that the camera's microphone
is on in the Reolink app.

**Sync recordings fails with "the download did not finish"** — over 4G a long recording of the main
stream can take more than the 5 minutes allowed for one file. Choose `sd_stream: sub`, or copy only
the newest recording after a motion alert.

**A recorded live view is long but shows only a moment, and the battery ran down** — up to 0.3.1 a
live view whose camera stopped sending after a few frames waited for the next one forever and kept
the camera connected (the log shows `Buffer full on vidsrc ...`, then only `Connection Lost` every 30
minutes). From 0.3.4 such a live view ends after 20 s without a frame and the camera goes back to
sleep (0.3.2 and 0.3.3 ended the live view but could still keep the camera connected). Delete the file by hand.

**Copying a recording from the SD card takes minutes** — over 4G (Reolink's relay) the main stream
comes at about 75 KB/s: a 37-second recording (16 MB) takes about 3.5 minutes, and recordings are
copied one after another. Choose `sd_stream: sub` for copies in seconds (a smaller picture). Up to
0.3.2 opening the list also searched the whole card first (another 3.5 minutes).

## The fork
What the patches add and the WebSocket protocol: [FORK.md](FORK.md).
