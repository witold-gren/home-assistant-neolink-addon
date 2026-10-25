#!/bin/bash
# Neolink in ws-rtsp mode: configuration from the app options, secrets in /data, discovery for the integration.
set -euo pipefail

OPTIONS=/data/options.json
CONFIG=/data/neolink.toml
WS_PORT=3002
RTSP_PORT=8554
log() { echo "[neolink-addon] $*"; }

# API token and RTSP password: random on the first start, then kept (the integration knows them).
secret() {
    local file="/data/$1"
    [ -s "${file}" ] || head -c 24 /dev/urandom | base64 | tr -d '/+=\n' > "${file}"
    chmod 600 "${file}"
    cat "${file}"
}
WS_TOKEN=$(secret ws_token)
RTSP_USER=ha
RTSP_PASSWORD=$(secret rtsp_password)

jq -r --argjson push "$(jq '.push' "${OPTIONS}")" --arg token "${WS_TOKEN}" --arg ruser "${RTSP_USER}" --arg rpass "${RTSP_PASSWORD}" '
  def s: tojson;
  [
    "bind = \"0.0.0.0\"",
    "bind_port = '"${RTSP_PORT}"'",
    "",
    "[websocket]",
    "port = '"${WS_PORT}"'",
    "token = \($token | s)",
    "battery_update = \(.battery_minutes * 60000)",
    "enable_motion = \(.motion)",
    "motion_timeout = \(.motion_seconds)",
    "snapshot_dir = \"/data/snapshots\"",
    "",
    "[[users]]",
    "name = \($ruser | s)",
    "pass = \($rpass | s)",
    "",
    (.cameras[] |
      "[[cameras]]",
      "name = \(.name | s)",
      "username = \(.username | s)",
      "password = \(.password | s)",
      "uid = \(.uid | s)",
      "discovery = \(.discovery | s)",
      "stream = \(.stream | s)",
      "idle_disconnect = \(.idle_disconnect)",
      # Motion from Reolink push notifications (Firebase); the camera does not have to be connected.
      "push_notifications = \($push)",
      ""
    )
  ] | .[]
' "${OPTIONS}" > "${CONFIG}"
chmod 600 "${CONFIG}"
log "Cameras: $(jq -r '[.cameras[].name] | join(", ")' "${OPTIONS}")"
log "RTSP: rtsp://${RTSP_USER}:<password>@<HA address>:8564/<name>/sub (password in /data/rtsp_password)"

# Discovery for the integration once the WebSocket API answers.
announce() {
    [ -n "${SUPERVISOR_TOKEN:-}" ] || return 0
    for _ in $(seq 1 60); do
        curl -fsS "http://127.0.0.1:${WS_PORT}/healthz" >/dev/null 2>&1 && break
        sleep 1
    done
    local host
    host=$(curl -fsS -H "Authorization: Bearer ${SUPERVISOR_TOKEN}" http://supervisor/addons/self/info | jq -r '.data.hostname')
    jq -n --arg host "${host}" --arg token "${WS_TOKEN}" --arg ruser "${RTSP_USER}" --arg rpass "${RTSP_PASSWORD}" \
        --argjson port "${WS_PORT}" --argjson rport "${RTSP_PORT}" \
        '{service: "neolink", config: {host: $host, port: $port, token: $token,
          rtsp_port: $rport, rtsp_username: $ruser, rtsp_password: $rpass}}' \
      | curl -fsS -X POST -H "Authorization: Bearer ${SUPERVISOR_TOKEN}" -H "Content-Type: application/json" \
          --data @- http://supervisor/discovery >/dev/null \
      && log "Announced to the Neolink integration: ${host}:${WS_PORT}" \
      || log "Could not announce to the integration (add it by hand)"
}
announce &

# The Firebase token for push notifications (dirs::config_dir) survives restarts in /data.
export XDG_CONFIG_HOME=/data/config
mkdir -p "${XDG_CONFIG_HOME}"
# log_level: debug -> details from Neolink itself only (e.g. "push payload: ..." with the content of
# the Reolink notification). Other libraries and the camera protocol (neolink_core) stay at info,
# otherwise network messages flood the log. The filter matches by prefix, hence the exceptions.
LOG_LEVEL="$(jq -r '.log_level' "${OPTIONS}")"
if [ "${LOG_LEVEL}" = "debug" ]; then
  export RUST_LOG="info,neolink=debug,neolink_core=info,neolink_decoder=info"
  log "Log: debug for Neolink (look for 'push payload:' lines after motion)"
else
  export RUST_LOG="${LOG_LEVEL}"
fi
exec /usr/local/bin/neolink ws-rtsp --config "${CONFIG}"
