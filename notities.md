# Notities homelab

## 2026-10-30: overzicht, updates en arr-stack gerepareerd

**Gedaan**
- Overzicht van de hele setup gemaakt (zie `inventaris.md`).
- SSH-sleutel `proxmox_claude` op de laptop gemaakt en op de server gezet.
- Handmatige back-up gemaakt van 100, 101 en 202 naar `local`.
- 204 updates geïnstalleerd: Proxmox 8.4.1 → 8.4.21, kernel 6.8.12-11 → 6.8.12-43. Server herstart; alles kwam weer op. Logboek: `/root/upgrade-2026-10-30.log` op de server.
- servarr (202) start nu automatisch (`onboot: 1`) en heeft 6 kernen in plaats van 2.

**Probleem: downloads kwamen "nergens" terecht**
- Oorzaak: de echte NZBGet uit het Docker-bestand draaide niet. Alleen een oude container `nzbget-test` bestond nog, zonder koppeling naar de downloadmap.
- Oplossing: `docker compose up -d nzbget` in `/mnt/appdata/yaml`. Oude `nzbget-test` verwijderd. Radarr en Sonarr wijzen al naar host `nzbget`, poort 6789.

**Probleem: Plex startte niet**
- Oorzaak 1: tikfout in het Docker-bestand (`ports: 32400:32400` moet een lijst zijn).
- Oorzaak 2: een oude, kapotte container `5e28499bb4dd_plex` bezette de naam. Verwijderd.
- Oorzaak 3: in `bridge`-modus gaf Plex "geen rechten" bij het koppelen van de server. Opgelost met `network_mode: host`.
- Reservekopieën van het oude bestand: `docker-compose.yaml.bak-2026-10-30*` in `/mnt/appdata/plexyaml`.

**Probleem: Plex traag op de telefoon**
- Oorzaak: een 4K-remux (HEVC, Dolby Vision, TrueHD) wordt voor de telefoon live omgezet op de processor. Dat waren 2 kernen, en er liepen 2 sessies tegelijk.
- Gedaan: 6 kernen. Advies: kwaliteit in de app op "Origineel", de tv via een kabel aansluiten.
- De videochip (`/dev/dri`) gebruiken kan alleen met Plex Pass, of gratis met Jellyfin.

## Nog te doen
1. NZBGet-wachtwoord veranderen. Het staat leesbaar in het Docker-bestand op de server: verplaatsen naar `.env`.
2. Opslag van Zigbee (100) vergroten van 4 naar 8 GB.
3. Automatische back-ups instellen, plus een kopie op een tweede plek.
4. Beveiliging: `lxc.cgroup2.devices.allow: a` en de USB-regels weghalen bij 100 (de stick zit via het netwerk). Rechten van 202 inperken (apparmor `unconfined`). SSH alleen met sleutel. Vaste IP-adressen voor HA en Zigbee.
5. Een download van begin tot eind testen (Radarr → NZBGet → Plex).
6. Later: upgrade naar Proxmox 9 (ondersteuning voor 8 loopt af), Radarr instellen op 4K WEB-DL, eventueel Jellyfin.
7. Oude back-up van 202 uit juni 2025 opruimen.
