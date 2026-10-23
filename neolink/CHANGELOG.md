# Changelog

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
