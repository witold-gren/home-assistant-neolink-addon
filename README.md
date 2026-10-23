# Neolink for Home Assistant — app (add-on)

Home Assistant app (formerly add-on) for **Reolink cameras without a local API** — battery cameras
without a Home Hub and 4G LTE cameras such as the Reolink Go Plus / Go G330. It runs a fork of
[Neolink](https://github.com/QuantumEntangledAndy/neolink) with a WebSocket API; entities come from the
[Neolink integration](https://github.com/witold-gren/home-assistant-neolink-integration). No MQTT.

What you get together with the integration:
- live video through RTSP (go2rtc / the camera entity) that never keeps a battery camera awake,
- snapshots from memory that do not wake the camera, plus the picture of the last motion event,
- motion and detection type (person, vehicle, animal) from Reolink push notifications, even while the
  camera sleeps,
- battery, charging, 4G signal, SD card and the camera settings (PIR, LED, infrared, recording, siren …).

## Installation
1. **Settings → Apps → App store → ⋮ → Repositories**, add
   `https://github.com/witold-gren/home-assistant-neolink-addon`.
2. Install **Neolink (Reolink battery & 4G cameras)** — Neolink is compiled during installation
   (a few minutes on a PC, much longer on a Raspberry Pi).
3. Add your cameras in the app configuration (name, UID, device password, discovery) and start it.
4. Install the [Neolink integration](https://github.com/witold-gren/home-assistant-neolink-integration)
   (HACS custom repository) — it is discovered automatically.

Documentation: [neolink/DOCS.md](neolink/DOCS.md); the fork and its WebSocket protocol:
[neolink/FORK.md](neolink/FORK.md).

## Repository layout
| Path | What it is |
|---|---|
| `neolink/` | the app: `config.yaml`, `Dockerfile` (builds the fork), `run.sh`, translations, docs |
| `neolink/patches/` | patches on top of upstream Neolink (WebSocket API, push notifications, RTSP fixes) |
| `deploy.sh` | development: copy the app to a mounted `addons` share |

## License
Neolink is AGPL-3.0-or-later (© the Neolink authors); the patches and this app are under the same
license — see [LICENSE](LICENSE).
