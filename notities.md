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

**Probleem: NZBGet startte toch niet (en wachtwoord stond leesbaar)**
- Oorzaak: een spatie na `=` in `NZBGET_USER= ...` en `NZBGET_PASS= ...`. Het startscript maakte daar losse woorden van, waardoor NZBGet alleen zijn hulptekst liet zien.
- Oplossing: beide regels uit het Docker-bestand gehaald (ook de spatie bij `TZ=`). Het wachtwoord staat nu alleen in NZBGet zelf (Settings → Security, bewaard in `nzbget.conf`) en is veranderd. Radarr en Sonarr zijn bijgewerkt; de "Test" van de download client slaagt in allebei.
- Reservekopie van het oude bestand (met het oude wachtwoord): `/root/docker-compose.yaml.bak-2026-10-30` in LXC 202. Opruimen zodra alles een tijdje goed werkt.

**Prowlarr gekoppeld aan Radarr en Sonarr**
- In Prowlarr → Settings → Apps: Radarr (`http://radarr:7878`) en Sonarr (`http://sonarr:8989`) toegevoegd, met Prowlarr-adres `http://prowlarr:9696` en "Full Sync".
- Het doorzetten van NZBPlanet lukte nog niet: NZBPlanet gaf `429 Too Many Requests` (daglimiet van het gratis account). Prowlarr probeert het vanzelf opnieuw.
- Daarna de oude losse zoekbronnen weghalen: "NZBPlanet" in Radarr en "Newznab" in Sonarr. Anders zoekt alles dubbel en is de limiet nog sneller op.
- Status: Newshosting-abonnement actief. NZBPlanet is een gratis account (geen VIP). Plex: lifetime Plex Pass.

## Nog te doen
1. ~~Opslag van Zigbee (100) vergroten van 4 naar 8 GB.~~ Gedaan op 2026-10-30 (`pct resize 100 rootfs +4G`, nu 30% vol).
2. ~~Automatische back-ups instellen.~~ Gedaan op 2026-10-30: opslag `backup2tb` op de 2 TB-schijf (met `is_mountpoint`, zodat er nooit naar een lege map wordt geschreven als de schijf mist) en een taak elke zondag om 03:00, de laatste 4 bewaard. Nog te doen: een kopie buiten huis (USB-schijf of cloud), en de back-ups van Home Assistant zelf naar bijvoorbeeld Google Drive.
3. Beveiliging:
   - ~~A. Zigbee (100): overbodige rechten weghalen.~~ Gedaan op 2026-10-30: `lxc.cgroup2.devices.allow`-regels, de lege `lxc.cap.drop:` en de USB-`lxc.mount.entry`-regels verwijderd. Zigbee2MQTT maakt na de herstart gewoon verbinding met de stick via het netwerk. Oude config: `/root/lxc-100.conf.bak-2026-10-30` op de host.
   - ~~B. SSH alleen met sleutel.~~ Gedaan op 2026-10-30: `/etc/ssh/sshd_config.d/10-alleen-sleutel.conf` (`PermitRootLogin prohibit-password`, `PasswordAuthentication no`). Getest: de sleutel werkt, een wachtwoord wordt geweigerd. De Proxmox-webpagina en de Shell daarin werken nog met je wachtwoord. Een nieuw apparaat toegang geven: de publieke sleutel via de webpagina-Shell toevoegen aan `/root/.ssh/authorized_keys`.
   - **C. servarr (202): rechten inperken** (`lxc.apparmor.profile: unconfined`, `devices.allow: a`, lege `cap.drop`) en alleen `/dev/dri` doorgeven voor Plex-hardwaretranscoding (Plex Pass). Samen doen, met de back-up bij de hand en daarna een test van Docker.
   - D. Vaste IP-adressen: volgens de eigenaar al ingesteld in de router (DHCP-reservering). Zigbee hield 192.168.1.58 na een herstart. Controleren in de router als dat zo uitkomt.
4. Een download van begin tot eind testen (Radarr → NZBGet → Plex).
5. Later: upgrade naar Proxmox 9 (ondersteuning voor 8 loopt af), Radarr instellen op 4K WEB-DL, apps bijwerken, Overseerr en Bazarr instellen, Plex de videochip laten gebruiken (kan met Plex Pass), Tailscale.
6. Oude back-up van 202 uit juni 2025 opruimen.
7. Later, in een aparte Home Assistant-sessie (toegang via `HA_TOKEN` in `.env`): kapotte dashboardkaarten opruimen ("Mobile IOS" verwijst naar 5 verdwenen automatiseringen, "OLD Mobile" naar 4 verdwenen lampen), het lege tabblad "Verdiepingen", 86 onbeschikbare entiteiten doorlopen, tikfout "auromatisering".
