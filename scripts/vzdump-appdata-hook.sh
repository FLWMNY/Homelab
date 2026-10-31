#!/bin/bash
# Proxmox vzdump-hook (staat op de host in /usr/local/bin/vzdump-appdata-hook.sh).
# Bij de start van een back-uptaak: de apps in servarr (LXC 202) even stoppen,
# /mnt/nvme1n1/servarr/appdata inpakken naar /mnt/nvme1n1/backups/appdata en de apps weer starten.
# Nodig omdat vzdump gekoppelde mappen (bind mounts) altijd overslaat.
# Daarnaast een kopie van de Samba-map `bestanden` (2 TB-schijf) naar de 500 GB-schijf.
# Alleen die kopie, met de hand:  vzdump-appdata-hook.sh bestanden
# Een fout hier laat de rest van de back-up gewoon doorgaan (altijd exit 0).
set -u

[ "${1:-}" = "job-start" ] || [ "${1:-}" = "bestanden" ] || exit 0

BRON=/mnt/nvme1n1/servarr
DOEL=/mnt/nvme1n1/backups/appdata
BEWAAR=4
CT=202
naam="appdata-$(date +%F_%H%M).tar.gz"

log() { echo "appdata-hook: $*"; }
apps() { pct exec "$CT" -- sh -c "cd /mnt/appdata/yaml && docker compose $1 >/dev/null 2>&1; cd /mnt/appdata/plexyaml && docker compose $1 >/dev/null 2>&1"; }

# Weekmappen met hardlinks (--link-dest): een ongewijzigd bestand kost maar één keer ruimte.
# shortcut: max. 50 GB, omdat Proxmox zelf op de 500 GB-schijf draait; groter → een andere plek kiezen.
bestanden_kopie() {
  local bron=/mnt/nvme1n1/bestanden doel=/var/lib/vz/bestanden-kopie max_gb=50
  mkdir -p "$doel"
  rm -rf "$doel"/*.deels
  local nodig vrij vorige nieuw
  nodig=$(du -s --block-size=1G "$bron" | cut -f1)
  vrij=$(df --output=avail -B1G "$doel" | tail -1)
  vorige=$(ls -1d "$doel"/20*[0-9] 2>/dev/null | tail -1)
  nieuw="$doel/$(date +%F_%H%M%S)"
  if [ "$nodig" -gt "$max_gb" ] || [ "$nodig" -gt "$((vrij - 20))" ]; then
    log "FOUT: bestanden is ${nodig} GB (${vrij} GB vrij, max. ${max_gb} GB): niet gekopieerd"
  elif rsync -a --delete ${vorige:+--link-dest="$vorige"} "$bron/" "$nieuw.deels/"; then
    mv "$nieuw.deels" "$nieuw"
    log "bestanden gekopieerd: $(basename "$nieuw")"
    ls -1d "$doel"/20*[0-9] | head -n -"$BEWAAR" | while read -r oud; do
      rm -rf -- "$oud"; log "opgeruimd: bestanden $(basename "$oud")"
    done
  else
    rm -rf "$nieuw.deels"
    log "FOUT: kopie van bestanden mislukt, oude kopieën niet aangeraakt"
  fi
}

bestanden_kopie
[ "$1" = "bestanden" ] && exit 0

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
