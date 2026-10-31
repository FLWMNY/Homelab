#!/usr/bin/env bash
# Kopieert de nieuwste back-ups van de Proxmox-server naar de externe SSD.
# Per VM/container de nieuwste vzdump uit `backup2tb`, plus de nieuwste appdata-back-up.
# Elk bestand wordt gecontroleerd met een sha256-controlegetal.
# Op de SSD blijven alleen de laatste $BEWAAR datummappen staan.
#
# Gebruik (Git Bash op de laptop):  bash scripts/backup-naar-ssd.sh
set -euo pipefail

DOEL="${DOEL:-/d/Homelab/Back-ups}"
BEWAAR="${BEWAAR:-3}"
SERVER="root@192.168.1.201"
SLEUTEL="$HOME/.ssh/proxmox_claude"
BRON="/mnt/nvme1n1/backups"
ssh_server() { ssh -i "$SLEUTEL" -o BatchMode=yes "$SERVER" "$@"; }

# Oudere datummappen weg, de nieuwste $BEWAAR blijven. Alleen mappen met een datumnaam (JJJJ-MM-DD).
opruimen() {
  local map="$1" bewaar="$2"
  ls -1 "$map" | grep -E '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' | sort -r | tail -n +"$((bewaar + 1))" | while read -r oud; do
    echo "Oude back-up verwijderd: $oud"
    rm -rf -- "${map:?}/$oud"
  done
}

if [[ "${1:-}" == "--zelftest" ]]; then
  t=$(mktemp -d)
  mkdir -p "$t"/{2026-10-01,2026-10-08,2026-10-15,2026-10-22,anders}
  opruimen "$t" 3 >/dev/null
  [[ "$(ls -1 "$t" | tr '\n' ' ')" == "2026-10-08 2026-10-15 2026-10-22 anders " ]] && echo "zelftest OK" || { echo "zelftest MISLUKT: $(ls "$t")"; exit 1; }
  rm -rf "$t"; exit 0
fi

[[ -d "$DOEL" ]] || { echo "Map $DOEL niet gevonden. Is de SSD aangesloten?"; exit 1; }

# Op de server: welke bestanden zijn de nieuwste, en hun controlegetal.
lijst=$(ssh_server "
  {
    for id in \$( (pct list; qm list) | awk '\$1 ~ /^[0-9]+\$/ {print \$1}' | sort -u); do
      ls -1t $BRON/dump/vzdump-*-\$id-*.{tar.zst,vma.zst} 2>/dev/null | head -1
    done
    ls -1t $BRON/appdata/*.tar.gz 2>/dev/null | head -1
  } | xargs -r sha256sum
")

[[ -n "$lijst" ]] || { echo "Geen back-ups gevonden op de server."; exit 1; }

vandaag="$DOEL/$(date +%F)"
mkdir -p "$vandaag"
echo "Kopiëren naar $vandaag ..."

fout=0
while read -r som pad; do
  naam=$(basename "$pad")
  if [[ -f "$vandaag/$naam" ]] && [[ "$(sha256sum "$vandaag/$naam" | cut -d' ' -f1)" == "$som" ]]; then
    echo "  al aanwezig en goed: $naam"; continue
  fi
  echo "  ophalen: $naam"
  scp -q -i "$SLEUTEL" -o BatchMode=yes "$SERVER:$pad" "$vandaag/$naam"
  if [[ "$(sha256sum "$vandaag/$naam" | cut -d' ' -f1)" == "$som" ]]; then
    echo "    gecontroleerd: OK"
  else
    echo "    FOUT: controlegetal klopt niet voor $naam"; fout=1
  fi
done <<< "$lijst"

echo "$lijst" > "$vandaag/sha256-controlegetallen.txt"

# De Samba-map `bestanden`: één actuele kopie in $DOEL/bestanden (geen 3 datummappen, om ruimte op de SSD te sparen).
# shortcut: bestandsnamen met tekens die Windows niet toestaat (: ? * enz.) mislukken; dan krijg je een FOUT.
echo "Kopiëren: map bestanden ..."
nieuw="$DOEL/bestanden.nieuw"
rm -rf -- "$nieuw"; mkdir -p "$nieuw"
if ssh_server "tar -C /mnt/nvme1n1/bestanden -cf - ." | tar --no-same-owner -xf - -C "$nieuw" \
   && ssh_server "cd /mnt/nvme1n1/bestanden && find . -type f -print0 | xargs -0r sha256sum" > "$nieuw.sha256" \
   && { [[ ! -s "$nieuw.sha256" ]] || (cd "$nieuw" && sha256sum --quiet -c "$nieuw.sha256"); }; then
  rm -rf -- "$DOEL/bestanden"; mv "$nieuw" "$DOEL/bestanden"; mv "$nieuw.sha256" "$DOEL/bestanden-sha256.txt"
  echo "  gecontroleerd: OK ($(wc -l < "$DOEL/bestanden-sha256.txt") bestanden)"
else
  echo "  FOUT: kopie van bestanden mislukt; de vorige kopie is niet aangeraakt"; fout=1
fi

if [[ $fout -ne 0 ]]; then
  echo "Er ging iets mis. Oude back-ups zijn NIET opgeruimd."; exit 1
fi
opruimen "$DOEL" "$BEWAAR"
echo "Klaar: $(ls -1 "$vandaag" | grep -vc sha256) bestanden, $(du -sh "$vandaag" | cut -f1)."
