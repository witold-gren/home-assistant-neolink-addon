# The Neolink fork with a WebSocket API

Patches on top of [QuantumEntangledAndy/neolink](https://github.com/QuantumEntangledAndy/neolink)
`6e05e78` (0.6.3-rc.3), AGPL-3.0-or-later, in [patches/](patches) — applied and compiled by the
app's Dockerfile:

- `ws` and `ws-rtsp` modes: `GET /ws` (hello, commands, state events), `GET /snapshot/{camera}`
  (JPEG; `?cached=true` only from memory without waking the camera, 404 when none; `?max_age=<s>`),
  `GET /healthz`, optional token; background reads never wake battery cameras;
- the cached picture is refreshed passively while the camera is connected anyway (`snapshot_refresh`,
  seconds, default 60) and saved in `snapshot_dir` (survives restarts);
- RTSP ignores a `#...` fragment in the path (`#timeout=60` for go2rtc);
- Reolink push notifications: a receiver on fcm-push-listener 4 (Firebase registration with the
  Reolink Android app identifiers; the old GCM registration stopped working in June 2024), the
  `pushnoti` feature on by default; in the API `motion` stays on for `motion_timeout` s after a
  notification, plus `last_motion`, `last_detection` (person / vehicle / animal / motion) and
  `snapshot_at`;
- an RTSP stream never keeps a battery camera awake without a client: a one-frame buffer instead of a
  blocking pool (#340), `appsrc` flushing or not playing ends the stream after 15 s, and the stream
  task ends when nobody takes frames for 15 s;
- optional PIR XML fields (`rfID`, `sensitivity`, `timeBlockList`, `alarmHandle`): the Reolink Go Plus
  does not send them and a parse error dropped the connection;
- log timestamps in local time (`TZ`);
- the camera's sound in RTSP as two tracks, AAC (`pay1`, for HLS and recordings) and Opus (`pay2`, for
  WebRTC), instead of raw PCM (`rtpL16pay`);
- recorded live views: `[websocket] record_dir` (and `record_switches`, default `<record_dir>/.switches`)
  turn it on; while an RTSP client watches a camera whose switch is on, the frames it gets are muxed
  as they come into a fragmented mp4, `<record_dir>/<camera>/<YYYY-MM-DD>/HHMMSS-HHMMSS.mp4` (local
  time; `HHMMSS-recording.mp4` while written, renamed after a crash on the next start). One recording
  per camera at a time; ADPCM sound is left out (AAC is kept);
- talking through the speaker: `GET /talk/{camera}?rate=<Hz>` (WebSocket, token as for `/ws`) takes
  binary frames of PCM s16le mono at `rate` (8000-48000), encodes them with GStreamer to the camera's
  ADPCM (`TalkAbility`, e.g. DVI 16 kHz, blocks of `lengthPerEncoder / 2 + 4` bytes) and streams them
  to the camera; the text `stop` or closing the socket ends it. On the way it sends
  `{"state": "connecting"}` (at once) and `{"state": "connected"}` (the camera answered); the last
  message is `{"ok": true}` or
  `{"ok": false, "error": "busy" | "no_speaker" | "unreachable" | "failed"}`; one talker per camera;
- the siren on and off: `siren` with `on` uses the manual mode of reolink_aio (`audioPlayInfo`
  `playMode` 2, `onOff` 1/0, msg 263) and switches itself off after `seconds`; without `on` it sounds
  once as upstream;
- SD card recordings: search by the camera's calendar (`DayRecords` 142, a month at a time) and then
  per day with `findAlarmVideo` (272/273/274, reolink_aio `search_vod_type`), or, on cameras that
  answer it with 405 (a Go Plus), the older `FileInfoList` (14/15/16, host channel 250 in the
  header); download by time (143, stopped by 144) or by replaying one file (5, message number 0,
  stopped by 7, ending when the data goes quiet). The frames are muxed with their own times into
  `<record_dir>/<camera>/<YYYY-MM-DD>/HHMMSS-HHMMSS.mp4` (`….mp4.part` while written; the codec is
  read from the frames, as the card's main stream of a Go Plus is H.265 labelled H.264). Cover
  thumbnails: `CoverPreview` (298), or else the first I-frame of a replay of the sub stream file,
  as a JPEG in `<snapshot_dir>/sd/<camera>/`, served at `GET /sd_thumbnail/{camera}/{day}/{file}.jpg`.
  The list is kept in `<snapshot_dir>/sd/<camera>/list.json`. Nothing on the card is deleted. The
  wire formats of the older messages come from the decrypted Reolink app captures in
  [nodelink-js](https://github.com/apocaliss92/nodelink-js) (MIT); `coverpreview-298-payload.bin`
  in the core samples is one of them;
- binary payloads with `encryptLen` keep their unencrypted rest (only the first `encryptLen` bytes
  are AES; the rest was cut off).

## WebSocket protocol
The client sends `{"id": 1, "command": "...", "camera": "Garden", "args": {...}}`, the bridge answers
`{"type": "result", "id": 1, "success": true, "result": {...}}` or `"success": false, "error"`.

| Command | Arguments | Wakes the camera |
|---|---|---|
| `list` | - | no |
| `led`, `pir` | `on: bool` | yes |
| `ir` | `state: on\|off\|auto` | yes |
| `reboot` | - | yes |
| `siren` | - (sounds once), or `on: bool`, `seconds: 1-900` (default 30) | yes |
| `sd_recordings` | the kept list at once (`updated`, `refreshing`, `error`, `recordings`: `file`, `start`, `end`, `kinds`, `size`, `local`, `downloading`, `copy_error`, `thumbnail`); `refresh: true` searches the card in the background (`days`, default 365, or `hours`; `wait: true` waits for it), `thumbnails: [file]` fetches those covers first | with `refresh` |
| `sd_auto` | `on: bool`: copy the newest recording 5 minutes after each motion notification (kept across restarts, off by default; state `sd_auto`) | no |
| `sd_sync` | `files: [file]` (from the list), or `hours: int` (default 24) with `latest: bool`; copies one by one in the background, more can be asked meanwhile; progress in `sd_sync` (`pending`) | yes |
| `battery`, `refresh` | - | yes |
| `snapshot` | - (result `jpeg` in base64) | yes |
| `wakeup` | `minutes: int` | yes |
| `pir_sensitivity` | `value: 1-100` | yes |
| `pir_reduce_false_alarm`, `recording`, `alarm_sound` | `on: bool` | yes |
| `post_record` | `seconds: int` (one of `post_record_options`, e.g. 8/15/30) | yes |
| `push` | `on: bool` (push notifications from the camera; off = no motion in HA) | yes |
| `record_live` | `on: bool` (record watched live views; local, see above) | no |
| `probe` | `msg_id: int` (diagnostics: answer code; XML in the log with the camera's `debug = true`) | yes |

`GET /snapshot/{camera}?event=true` returns the picture taken after the last motion notification
(`<camera>.event.jpg` in `snapshot_dir`, time in `event_snapshot_at`).

Baichuan commands used for the settings (checked on a Reolink Go Plus): `rfAlarmCfg` 212/213
(`sensiValue`, `reduceFalseAlarm`), `Record` 81/82 (`enable`), `RecordCfg` 54/55 (`recordDelayTime`,
`timeList`), `AudioTask` 232/231 (`enable`), `PushTask` 219/218 (`enable`), `HddInfoList` 102 (SD
card), `Net3g4gInfo` 255 (4G signal; the camera sends it by itself every few seconds, a query
returns 405).

Events: `{"type": "event", "event": "state", "camera": "...", "state": {...}}` on every change
(connection, battery, LED/IR/PIR, motion, `record_live`, `recording_live`, `siren_on`, `sd_sync`, `sd_auto`). The first message after connecting:
`{"type": "hello", "version": "...", "cameras": [...]}`.
