#!/bin/sh
# Development deploy: copy the app to a mounted Samba "addons" share (default /Volumes/addons,
# override with ADDONS=...). Home Assistant then builds it as a local app (compiles Neolink).
set -e
HERE="$(cd "$(dirname "$0")" && pwd)"
ADDONS="${ADDONS:-/Volumes/addons}"
[ -d "$ADDONS" ] || { echo "Mount the Home Assistant addons share first ($ADDONS)"; exit 1; }
# Samba: --inplace, renaming temporary files is sometimes rejected
rsync -a --inplace --delete --exclude '.DS_Store' "$HERE/neolink/" "$ADDONS/neolink/"
echo "Deployed app $(grep '^version' "$HERE/neolink/config.yaml")"
