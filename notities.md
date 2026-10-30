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
- 2026-10-30 (avond): NZBPlanet VIP gekocht. In Prowlarr stond de indexer na de fouten tijdelijk uit; een indexer-test heeft dat opgeheven. Sync opnieuw gedraaid: Radarr en Sonarr hebben nu "NzbPlanet (Prowlarr)".
- De oude losse zoekbronnen zijn verwijderd ("NZBPlanet" in Radarr, "Newznab" in Sonarr). Alle zoekbronnen beheer je voortaan alleen in Prowlarr. De test van "NzbPlanet (Prowlarr)" slaagt in beide.
- Status: Newshosting-abonnement actief. NZBPlanet VIP. Plex: lifetime Plex Pass.

**Plex scant automatisch, Overseerr ingesteld, eindtest geslaagd**
- Plex: "Mijn bibliotheek automatisch scannen" en de gedeeltelijke scan staan aan.
- Overseerr: Plex-server `192.168.1.202:32400` (zonder SSL, bibliotheken Films en Tv-series), Radarr `radarr:7878` → `/movies`, Sonarr `sonarr:8989` → `/series` met seizoensmappen, allebei HD-1080p en standaard. De API-sleutels heeft de eigenaar zelf ingevuld.
- Eindtest: "Spider-Man: Brand New Day" aangevraagd in Overseerr → Radarr pakte binnen enkele seconden een 1080p-release van 2,6 GB → NZBGet → geïmporteerd naar `/movies/Spider-Man - Brand New Day (2026)` → Plex scande de map meteen. De hele keten duurde ongeveer 2 minuten.
- Let op: fanfilms en video's zonder releasedatum (zoals "If Saitama Was in Jujutsu Kaisen") worden niet gezocht, omdat Radarr alleen uitgebrachte films zoekt. Die aanvraag is weer verwijderd uit Overseerr en Radarr.

**Videochip voor Plex: werkt niet (AMD)**
- Met `/dev/dri` in de Plex-container meldt Plex: "hardware transcoding: enabled, but no hardware decode accelerator found". De AMD Radeon (Barcelo) wordt door Plex niet gebruikt, en het omzetten bleef hangen. Daarom is `/dev/dri` weer uit het Plex-bestand gehaald. De chip wordt nog wel aan LXC 202 doorgegeven (`dev0`/`dev1`), voor als we later Jellyfin proberen (dat ondersteunt AMD/VAAPI wel).

**Afspelen op de telefoon (Samsung S24 Ultra)**
- Op de laptop (browser) speelt alles goed af. De server is dus in orde.
- Met kwaliteit "Origineel" kreeg de telefoon de volle 4K-remux (~60 MB per stukje): te veel voor de wifi. Advies: tv op "Origineel", telefoon op 1080p of "Automatisch".
- Ook Spider-Man (1080p HEVC 10-bit, ~2,5 Mbps) bleef hangen op de telefoon, ook met "Direct Play" en "Direct Stream" uit (de server zette hem toen wél vlot om naar H.264). Waarschijnlijke oorzaak: de telefoon zat in het tuinhuis op een draadloze Deco zonder kabel. Nog te testen in huis. Kijken op de telefoon heeft geen prioriteit; aanvragen via Overseerr werkt wel.

**Apps bijgewerkt (2026-10-30)**
- Eerst een back-up van alle instellingen: `/mnt/nvme1n1/backups/appdata/appdata-2026-10-30-voor-update.tar.gz` (46 MB, zonder Plex-cache). Terugzetten: apps stoppen, de map `appdata` uitpakken over `/mnt/nvme1n1/servarr/`, en weer starten.
- `docker compose pull` + `up -d` in `/mnt/appdata/yaml` en `/mnt/appdata/plexyaml`, daarna `docker image prune -f` (2,1 GB vrijgemaakt).
- Nieuwe versies: Radarr 5.25 → **6.4.4**, Prowlarr 1.37 → **2.7.0**, Sonarr 4.0.14 → **4.0.20**, Overseerr 1.34 → **1.35.0**, Plex 1.41.7 → **1.43.5**. Bazarr en NZBGet naar de nieuwste versie.
- Getest: geen meldingen, en de zoekbron- en downloadtests slagen in Radarr en Sonarr.
- Updaten in het vervolg: dezelfde twee commando's, met eerst een back-up van `appdata`. Die zit niet in de wekelijkse Proxmox-back-up.

## Nog te doen
1. ~~Opslag van Zigbee (100) vergroten van 4 naar 8 GB.~~ Gedaan op 2026-10-30 (`pct resize 100 rootfs +4G`, nu 30% vol).
2. ~~Automatische back-ups instellen.~~ Gedaan op 2026-10-30: opslag `backup2tb` op de 2 TB-schijf (met `is_mountpoint`, zodat er nooit naar een lege map wordt geschreven als de schijf mist) en een taak elke zondag om 03:00, de laatste 4 bewaard. Nog te doen: een kopie buiten huis (USB-schijf of cloud), en de back-ups van Home Assistant zelf naar bijvoorbeeld Google Drive.
3. Beveiliging:
   - ~~A. Zigbee (100): overbodige rechten weghalen.~~ Gedaan op 2026-10-30: `lxc.cgroup2.devices.allow`-regels, de lege `lxc.cap.drop:` en de USB-`lxc.mount.entry`-regels verwijderd. Zigbee2MQTT maakt na de herstart gewoon verbinding met de stick via het netwerk. Oude config: `/root/lxc-100.conf.bak-2026-10-30` op de host.
   - ~~B. SSH alleen met sleutel.~~ Gedaan op 2026-10-30: `/etc/ssh/sshd_config.d/10-alleen-sleutel.conf` (`PermitRootLogin prohibit-password`, `PasswordAuthentication no`). Getest: de sleutel werkt, een wachtwoord wordt geweigerd. De Proxmox-webpagina en de Shell daarin werken nog met je wachtwoord. Een nieuw apparaat toegang geven: de publieke sleutel via de webpagina-Shell toevoegen aan `/root/.ssh/authorized_keys`.
   - ~~C. servarr (202): rechten inperken en videochip doorgeven.~~ Gedaan op 2026-10-30:
     - `lxc.cgroup2.devices.allow: a` en de lege `lxc.cap.drop:` verwijderd. Nu alleen `dev0: /dev/dri/renderD128,gid=108` en `dev1: /dev/dri/card0,gid=44`.
     - `lxc.apparmor.profile: unconfined` moest **terug**: zonder die regel kan Docker in deze *privileged* container zijn eigen AppArmor-profiel niet laden ("attempted to load a profile while confined"), en start geen enkele container. De echte oplossing is later servarr omzetten naar een *unprivileged* container (back-up terugzetten als unprivileged, en de rechten van de mappen aanpassen). Dat is een grotere klus.
     - Plex: `devices: - /dev/dri:/dev/dri` in het Docker-bestand. De container ziet de chip en zet hem zelf in de juiste groep. Of Plex de AMD-chip ook echt gebruikt, blijkt pas bij een afspeeltest.
     - Reservekopieën: `/root/lxc-202.conf.bak-2026-10-30` (host) en `docker-compose.yaml.bak-2026-10-30-gpu` (in `/mnt/appdata/plexyaml`).
   - D. Vaste IP-adressen: volgens de eigenaar al ingesteld in de router (DHCP-reservering). Zigbee hield 192.168.1.58 na een herstart. Controleren in de router als dat zo uitkomt.
4. ~~Een download van begin tot eind testen.~~ Geslaagd op 2026-10-30 (zie hierboven).
5. Later: upgrade naar Proxmox 9 (ondersteuning voor 8 loopt af), Radarr instellen op 4K WEB-DL, eventueel Jellyfin naast Plex (AMD-videochip werkt daar wel), servarr omzetten naar unprivileged (dan kan AppArmor aan), Tailscale, `appdata` meenemen in de automatische back-up.
6. Oude back-up van 202 uit juni 2025 opruimen.
7. Later, in een aparte Home Assistant-sessie (toegang via `HA_TOKEN` in `.env`): kapotte dashboardkaarten opruimen ("Mobile IOS" verwijst naar 5 verdwenen automatiseringen, "OLD Mobile" naar 4 verdwenen lampen), het lege tabblad "Verdiepingen", 86 onbeschikbare entiteiten doorlopen, tikfout "auromatisering".

## 2026-10-30 (avond): Bazarr ingesteld

- Bazarr draaide al, maar was nooit ingesteld. Nu via de Bazarr-API ingesteld (reservekopie van de oude config: `/root/bazarr-config.yaml.bak-2026-10-30` in LXC 202):
  - Gekoppeld aan Radarr (`radarr:7878`) en Sonarr (`sonarr:8989`).
  - Talen: Nederlands en Engels. Profiel "Nederlands + Engels" (allebei downloaden), standaard voor alle films en series.
  - Gratis bronnen zonder account: podnapisi, gestdown, yifysubtitles, embeddedsubtitles.
- Test: Black Panther en Spider-Man hebben al **ingebouwde** NL- en EN-ondertitels in het `.mkv`-bestand. Bazarr ziet dat en hoeft niets te downloaden. Bij nieuwe films zonder ingebouwde ondertitels zoekt Bazarr zelf.
- OpenSubtitles.com toegevoegd door de eigenaar (zelf de inlog ingevuld). Bazarr meldt de status "Good".

## 2026-10-30 (avond): beveiligingscontrole (alleen gekeken, niets veranderd)

**Van buitenaf (internet)**: geen beheerpagina's open. Wel staat UPnP aan op de router (192.168.1.1), en daarmee zijn automatisch 18 poorten opengezet:
- 24467/TCP → 192.168.1.202:32400 (Plex, voor kijken buiten de deur).
- 6881/TCP+UDP → 192.168.1.29 (de laptop; 6881 is de klassieke poort van een torrentprogramma).
- 15× UDP → 192.168.1.150 en .151 ("Ty-…", waarschijnlijk Tuya-slimme-apparaten zoals camera's of stekkers).

**Binnen het thuisnetwerk**: wie op de wifi zit (gasten, of een gehackt slim apparaat) kan bij:
- **Bazarr** zonder wachtwoord (toont onder meer de API-sleutels van Radarr en Sonarr).
- **Zigbee2MQTT-webpagina** (192.168.1.58:8080) zonder wachtwoord (apparaten koppelen of verwijderen).
- **Mosquitto (MQTT)** met `allow_anonymous true` (lampen en schakelaars aansturen).
- Proxmox-webpagina met alleen een wachtwoord, zonder tweestapsverificatie (gebruikers `root@pam` en `flow@pve`). De Proxmox-firewall staat uit. `rpcbind` (poort 111) staat aan maar is niet nodig.
- In orde: SSH alleen met sleutel; Radarr, Prowlarr (formulier), Sonarr (Basic), NZBGet, Overseerr, Plex en Home Assistant vragen om in te loggen.

## 2026-10-30 (avond): beveiliging stap 1, wachtwoorden op apps

- **Bazarr**: login aangezet door de eigenaar (Settings → **Application** → Security → Authentication: Form). In de nieuwe versie heet "General" nu "Application". Gecontroleerd: zonder login krijg je 401.
- **Zigbee2MQTT-webpagina**: auth token ingesteld door de eigenaar. Daarna Zigbee2MQTT herstart, anders werkt het niet.
- **Mosquitto (MQTT)**: reservekopie in LXC 100 `/root/backup-2026-10-30/` (map `mosquitto` + Zigbee2MQTT `configuration.yaml`).
  - `/etc/mosquitto/passwd` met de gebruikers `addons` (Zigbee2MQTT, hetzelfde wachtwoord als in zijn `configuration.yaml`) en `homeassistant` (nieuw; het wachtwoord staat in `.env` op de laptop als `MQTT_HA_PASSWORD`).
  - `/etc/mosquitto/conf.d/wachtwoorden.conf` met `password_file`, en `allow_anonymous false` in `mosquitto.conf`.
  - Home Assistant: MQTT-integratie opnieuw ingesteld met gebruiker `homeassistant`.
  - Getest: Zigbee2MQTT en Home Assistant loggen in met hun eigen gebruiker, een anonieme login wordt geweigerd (code 5), en alle 25 lampen zijn bereikbaar in HA.
  - Terugzetten: `cp -a /root/backup-2026-10-30/mosquitto/. /etc/mosquitto/ && rm /etc/mosquitto/conf.d/wachtwoorden.conf && systemctl restart mosquitto` (in LXC 100).

## 2026-10-30 (avond): beveiliging stap 2, UPnP uit

- Netwerk: Odido-router (Zyxel) op 192.168.1.1 is de router; de Deco-mesh geeft alleen wifi door (access point).
- De apparaten op .150/.151 met "Ty-UDP"-poorten zijn de Dreame-robotstofzuiger en de Reolink-deurbel/hub (wifi). Zigbee-sensoren hebben geen IP-adres. Poort 6881 (PCP) was het torrentprogramma op de laptop.
- De eigenaar heeft **UPnP** en **UPnP NAT-T** uitgezet in de Odido-router. Gecontroleerd: de router antwoordt niet meer op UPnP, dus de automatisch opengezette poorten zijn weg. Plex, Home Assistant en Overseerr werken thuis gewoon.
- Gevolgen: Plex buiten de deur gaat via de Plex-relay (nog niet nodig). Dreame en Reolink werken via hun eigen cloud. Torrents kunnen trager zijn.
- Tip voor later: UPnP ook uitzetten in de Reolink-app (Netwerk → Geavanceerd).
- Wens: Home Assistant buiten de deur gebruiken → via Tailscale, zonder open poorten.
