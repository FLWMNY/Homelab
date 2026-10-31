#!/bin/bash
# Proxmox vzdump-hook (staat op de host in /usr/local/bin/vzdump-appdata-hook.sh).
# Bij de start van een back-uptaak: de apps in servarr (LXC 202) even stoppen,
# /mnt/nvme1n1/servarr/appdata inpakken naar /mnt/nvme1n1/backups/appdata en de apps weer starten.
# Nodig omdat vzdump gekoppelde mappen (bind mounts) altijd overslaat.
# Een fout hier laat de rest van de back-up gewoon doorgaan (altijd exit 0).
set -u

[ "${1:-}" = "job-start" ] || exit 0

BRON=/mnt/nvme1n1/servarr
DOEL=/mnt/nvme1n1/backups/appdata
BEWAAR=4
CT=202
naam="appdata-$(date +%F_%H%M).tar.gz"

log() { echo "appdata-hook: $*"; }
apps() { pct exec "$CT" -- sh -c "cd /mnt/appdata/yaml && docker compose $1 >/dev/null 2>&1; cd /mnt/appdata/plexyaml && docker compose $1 >/dev/null 2>&1"; }

mkdir -p "$DOEL"
draait=0
if pct status "$CT" 2>/dev/null | grep -q running; then
  draait=1
  trap 'apps start; log "apps weer gestart"' EXIT
  log "apps stoppen"
  apps stop
fi

if tar --exclude="appdata/plex/Library/Application Support/Plex Media Server/Cache" \
       -C "$BRON" -czf "$DOEL/$naam.deels" appdata; then
  mv "$DOEL/$naam.deels" "$DOEL/$naam"
  chmod 600 "$DOEL/$naam"
  log "gemaakt: $naam ($(du -h "$DOEL/$naam" | cut -f1))"
  # alleen de nieuwste $BEWAAR bewaren
  ls -1t "$DOEL"/appdata-*.tar.gz | tail -n +"$((BEWAAR + 1))" | while read -r oud; do
    rm -f -- "$oud"; log "opgeruimd: $(basename "$oud")"
  done
else
  rm -f "$DOEL/$naam.deels"
  log "FOUT: inpakken mislukt, oude back-ups niet aangeraakt"
fi
[ "$draait" = 1 ] || log "LXC $CT draaide niet, apps niet gestopt"
exit 0
