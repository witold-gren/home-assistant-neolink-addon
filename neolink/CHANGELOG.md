# Changelog

## 0.4.0
- The live view of a sleeping camera opens in about 5 seconds instead of about 40, and its sound
  is in time with the picture. Home Assistant's WebRTC (go2rtc) waits only 5 seconds for each
  answer of the RTSP server, while the app answered only after the camera had woken (10-20 s over
  4G): WebRTC always failed and the browser fell back to HLS, slow to start and seconds behind.
  The app now keeps the start of each camera stream (codecs and the first frames, in
  `/data/snapshots/stream`) and answers a player at once with it while the camera wakes. The first
  live view after installing this version still waits for the camera, the next ones do not.
- Waking the camera is quicker: no fixed 4-second pause after the login, no 2-second wait for the
  repeats of the connection's confirmation, and the Reolink relay is tried at once for a 4G
  camera. Opened again right after the camera went to sleep, a live view no longer waits 15 s
  for a Reolink server that keeps answering "wait": a second registration starts after 5 s.
- A second player of a camera that is already awake gets its first frames in about a second
  (about 5 seconds before).
- Use it with the Neolink integration 0.4.0 or newer and its "WebRTC only" live view (the
  default): Home Assistant otherwise also opens an HLS stream next to WebRTC, a second stream of
  the camera over its mobile link.

## 0.3.5
- The app no longer stops when a live view ends while a player is still connecting. A camera that
  fell silent right after a player came made the player's PLAY wait for a frame; the end of that
  live view let the PLAY through without one and GStreamer's RTSP server stopped the whole app
  (`gst_rtsp_media_get_rates: assertion failed`), so every camera was unavailable until a restart.
  Such a PLAY is now answered 503 and the player tries again.

## 0.3.4
- A live view whose camera stops sending now really lets the camera go. 0.3.2 ended the live view
  itself, but the task reading the camera's stream kept waiting for data and held the camera
  connected (and connected it again after each lost connection). It now ends when nobody listens
  any more or after 20 seconds without data, so the camera sleeps 30 seconds later.

## 0.3.3
- Opening the list of the SD card no longer searches the whole card each time. Within a day of
  the last full search only what is new since the last search is asked for (seconds instead of
  minutes over 4G, with the camera awake), and copies asked for meanwhile no longer wait minutes
  behind the search. A full search still runs once a day, so recordings the card overwrote leave
  the list.

## 0.3.2
- A live view whose camera stops sending now ends after 20 seconds and lets go of the camera. Before,
  it waited for the next frame forever and kept the camera's session open: a battery camera stayed
  awake (reconnecting every 30 minutes) and drained its battery, and the recorded live view came out
  as a "90 minute" file holding less than a second of picture.
- A recorded live view's length and end time come from its first and last frame, not from when it
  was closed: a live view with less than a second of picture is not kept.

## 0.3.1
- SD card copies no longer fail with "Simultaneous subscription, Some(0)": fetching a cover now
  waits until its replay has let go of the camera's stream before the next copy starts.
- The newest recording copied after motion goes first in the queue, before older ones asked for by
  hand.
- The list of the card tells why the last copy of a recording failed (`copy_error`), so a dashboard
  can show it.

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
