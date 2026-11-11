# Changelog

## 0.3.0
- Recordings on the SD card copied to Home Assistant: the integration's "Sync recordings" button
  (or the `neolink.sync_recordings` action) searches the card, compares it with
  `/media/neolink/<camera>/` and downloads what is missing, named like the recorded live views
  (`<YYYY-MM-DD>/HHMMSS-HHMMSS.mp4`, the camera's own start and end), so they show on the same
  timeline. With `latest` only the newest one is copied (e.g. a few minutes after a motion alert).
  Option `sd_stream`: `main` (default, full quality) or `sub` (much less data over 4G).
  The list of the card (by its calendar, a year back) with cover thumbnails is kept for dashboards
  (the Neolink integration's `neolink/sd_recordings` and `neolink/sd_download`); a chosen
  recording can be copied on its own. Nothing on the card is ever deleted. Works on cameras with
  only the older messages of the Reolink app (a Go Plus answers the newer search with 405).
  Per camera, the integration's "Auto-copy recordings" switch copies the newest recording 5 minutes
  after each motion alert (off by default); browsing and copying by hand work either way.
- SD card work is done one operation at a time per camera (a search, a cover and a download shared
  the camera's replay channel and mixed their data); a download is ended only by its data stopping,
  not by a fixed time, and data left over from an interrupted one no longer fails the next.
- A live view shorter than a second is no longer kept (Home Assistant checking the stream left files
  of a fraction of a second). A card recording whose camera clock leaps (a Go Plus after its
  pre-recorded seconds) no longer comes out minutes long.
- The siren can be switched on and off (the Reolink app's manual siren) instead of only sounding
  once; it switches itself off after the time asked for (30 s by default).
- Talking reports how far it got: `{"state": "connecting"}` as soon as the talk opens and
  `{"state": "connected"}` once the camera answered, so a dashboard can show that a sleeping camera
  is being woken.

## 0.2.0
- Sound in the live view: RTSP carries the camera's sound as AAC and as Opus instead of raw PCM.
  Home Assistant's HLS player dropped PCM, and WebRTC through go2rtc had to transcode it with an
  ffmpeg that gave up while the camera woke, so the live view had no sound.
- Recorded live views: while someone watches a camera whose recording is switched on (switch in the
  Neolink integration), the live view is written without transcoding to
  `/media/neolink/<camera>/<YYYY-MM-DD>/HHMMSS-HHMMSS.mp4`. Options `record_cleanup` and
  `record_keep_days` delete old ones (off by default).
- Talking through the camera's speaker: `GET /talk/<camera>?rate=<Hz>` takes a browser microphone
  (PCM 16-bit mono over a WebSocket) and plays it on the camera, encoded to its ADPCM. The Neolink
  integration relays it for dashboards.

## 0.1.0
First public release.

- Runs a Neolink fork in `ws-rtsp` mode for Reolink battery and 4G LTE cameras without a local API
  (tested with a Reolink Go Plus / Go G330 over 4G), compiled from source while the app is installed.
- RTSP for each camera (password protected, `#timeout` fragments accepted for go2rtc); a stream never
  keeps a battery camera awake without a client.
- WebSocket API for the Neolink integration: camera state, commands, cached snapshots that never wake
  the camera, passive refresh while connected, the picture of the last motion event.
- Battery, charging, temperature, 4G signal (level, value, operator), SD card, LED, infrared, PIR
  (sensitivity, false-alarm reduction), recording and post-record time, alarm sound, siren, reboot,
  camera push setting.
- Motion from Reolink push notifications (Firebase) even while the camera sleeps, with the detection
  type (person, vehicle, animal, motion); the push registration is kept in `/data`.
- Discovery for the integration (host, port, token, RTSP credentials), local time in the log,
  `debug` logs the content of push notifications.
