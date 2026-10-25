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
- log timestamps in local time (`TZ`).

## WebSocket protocol
The client sends `{"id": 1, "command": "...", "camera": "Garden", "args": {...}}`, the bridge answers
`{"type": "result", "id": 1, "success": true, "result": {...}}` or `"success": false, "error"`.

| Command | Arguments | Wakes the camera |
|---|---|---|
| `list` | - | no |
| `led`, `pir` | `on: bool` | yes |
| `ir` | `state: on\|off\|auto` | yes |
| `reboot`, `siren` | - | yes |
| `battery`, `refresh` | - | yes |
| `snapshot` | - (result `jpeg` in base64) | yes |
| `wakeup` | `minutes: int` | yes |
| `pir_sensitivity` | `value: 1-100` | yes |
| `pir_reduce_false_alarm`, `recording`, `alarm_sound` | `on: bool` | yes |
| `post_record` | `seconds: int` (one of `post_record_options`, e.g. 8/15/30) | yes |
| `push` | `on: bool` (push notifications from the camera; off = no motion in HA) | yes |
| `probe` | `msg_id: int` (diagnostics: answer code; XML in the log with the camera's `debug = true`) | yes |

`GET /snapshot/{camera}?event=true` returns the picture taken after the last motion notification
(`<camera>.event.jpg` in `snapshot_dir`, time in `event_snapshot_at`).

Baichuan commands used for the settings (checked on a Reolink Go Plus): `rfAlarmCfg` 212/213
(`sensiValue`, `reduceFalseAlarm`), `Record` 81/82 (`enable`), `RecordCfg` 54/55 (`recordDelayTime`,
`timeList`), `AudioTask` 232/231 (`enable`), `PushTask` 219/218 (`enable`), `HddInfoList` 102 (SD
card), `Net3g4gInfo` 255 (4G signal; the camera sends it by itself every few seconds, a query
returns 405).

Events: `{"type": "event", "event": "state", "camera": "...", "state": {...}}` on every change
(connection, battery, LED/IR/PIR, motion). The first message after connecting:
`{"type": "hello", "version": "...", "cameras": [...]}`.
