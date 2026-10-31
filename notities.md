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
6. ~~Oude back-up van 202 uit juni 2025 opruimen.~~ Gedaan op 2026-10-31.
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

**Uitgesteld (op verzoek van de eigenaar), voor later:**
- Stap 3: tweestapsverificatie (TOTP) op Proxmox voor `root@pam`. (`flow@pve` is uitgezet op 2026-10-31.)
- Stap 4: gastenwifi voor bezoek en slimme apparaten (Dreame, Reolink).
- ~~Stap 5: `rpcbind` (poort 111) uitzetten.~~ Gedaan op 2026-10-31.
- Tailscale, voor Home Assistant buiten de deur.

## 2026-10-30 (avond): Tailscale

- Nieuwe LXC **103 "tailscale"**: Debian 12 (sjabloon `debian-12-standard_12.12-1`), unprivileged, 1 kern, 256 MB, 2 GB, `dev0: /dev/net/tun`, start automatisch.
- Tailscale 1.104.4 via het officiële installatiescript. IP-doorsturen aan (`/etc/sysctl.d/99-tailscale.conf`). Gestart met `tailscale up --advertise-routes=192.168.1.0/24 --hostname=thuis-toegang --accept-dns=false`.
- De eigenaar heeft de machine aan zijn account gekoppeld, de route 192.168.1.0/24 goedgekeurd en "key expiry" uitgezet.
- Getest: via 4G (wifi uit) op de iPhone met de Tailscale-app opent Home Assistant op http://192.168.1.184:8123.
- Volgende stappen: Vaultwarden (eigen LXC, met eigen Tailscale-aansluiting voor HTTPS), daarna Samba.

## 2026-10-30 (avond): Vaultwarden

- Nieuwe LXC **104 "vaultwarden"**: Debian 12, unprivileged (`nesting=1,keyctl=1`), 1 kern, 512 MB, 4 GB, `dev0: /dev/net/tun`, start automatisch.
- Docker via get.docker.com. Vaultwarden via `diensten/vaultwarden/docker-compose.yml` in `/opt/vaultwarden`; de data staat in `/opt/vaultwarden/data` (zit in de wekelijkse Proxmox-back-up van LXC 104).
- Vaultwarden luistert alleen op `127.0.0.1:8080`. Eigen Tailscale-machine "vaultwarden" (key expiry uit) met `tailscale serve --bg http://127.0.0.1:8080` → **https://vaultwarden.tailf6fed1.ts.net** (geldig certificaat, alleen binnen het tailnet). Vanaf het thuisnetwerk zonder Tailscale is hij niet bereikbaar (getest).
- De eigenaar heeft zijn account aangemaakt (1 gebruiker). Daarna `SIGNUPS_ALLOWED=false`; getest: een nieuwe registratie wordt geweigerd. De beheerpagina (`ADMIN_TOKEN`) staat uit.
- Nog te doen: Bitwarden-apps op laptop, Windows-pc, S24 en iPhone (server: "zelf gehost" met het adres hierboven), LastPass importeren (exportbestand daarna veilig verwijderen), en een **back-up buiten huis** (nu belangrijk vanwege de kluis).
- LastPass geïmporteerd (61 items) via de webkluis op de laptop (Tools → Import → "LastPass (csv)"). Het CSV-bestand heeft de eigenaar zelf afgehandeld en daarna verwijderd. Bitwarden werkt op de laptop (Edge), de iPhone en de S24.
- Let op: zonder push-meldingen synchroniseren de apps niet vanzelf na een wijziging. Handmatig: Bitwarden → Instellingen → Kluis → Synchroniseren. Tailscale moet daarvoor aan staan. Mogelijke verbetering: push via bitwarden.com/host (gratis installatie-id en sleutel; alleen een seintje, geen kluisdata).
- Les: de S24 zat eerst niet in Tailscale, en de iPhone had Tailscale uit. Dan geeft Bitwarden een vage foutmelding.
- Later: LastPass-account verwijderen na een paar weken, belangrijke wachtwoorden vernieuwen (LastPass-lek 2022), LastPass Authenticator-codes overzetten.

## 2026-10-31: back-up naar de externe SSD

- Verse back-ups van LXC 103 en 104 gemaakt (`backup2tb`), omdat die nog geen back-up hadden.
- Script `scripts/backup-naar-ssd.sh` (Git Bash op de laptop): haalt per VM/LXC de nieuwste vzdump plus de nieuwste `appdata`-back-up op, en zet ze in `D:\Homelab\Back-ups\JJJJ-MM-DD\`. Elk bestand wordt gecontroleerd met sha256. Alleen de laatste 3 datummappen blijven bewaard; bij een fout wordt er niets opgeruimd. Zelftest: `bash scripts/backup-naar-ssd.sh --zelftest`.
- Eerste run: 6 bestanden, 7,6 GB, alles "gecontroleerd: OK". Duurde 38 minuten via wifi (~3,5 MB/s); met een kabel gaat het sneller.
- Let op: de SSD is niet versleuteld (de back-ups bevatten API-sleutels en de MQTT-wachtwoorden; de Vaultwarden-kluis zelf is wel versleuteld). Neem de SSD af en toe mee buiten huis.
- Nog te doen: de Samba-map `bestanden` meenemen, en het script regelmatig laten draaien.

## 2026-10-31: Samba (gedeelde map)

- Router-DHCP deelt .2 t/m .200 uit; **.201–.254 zijn voor vaste adressen** (Proxmox .201, servarr .202, samba .203).
- Map op de host: `/mnt/nvme1n1/bestanden` (eigenaar 101000:101000 = uid 1000 in de unprivileged container).
- Nieuwe LXC **105 "samba"**: Debian 12, unprivileged, 1 kern, 256 MB, 2 GB, `mp0` naar `/srv/bestanden`, vast IP **192.168.1.203** (reservekopie van de oude config: `/root/lxc-105.conf.bak-2026-10-31` op de host).
- Samba 4.17 met `diensten/samba/smb.conf`: share "Bestanden", alleen gebruiker `floriano`, minimaal SMB3, geen gasttoegang, nmbd uit. Het wachtwoord staat in `.env` (`SMB_PASSWORD`).
- Getest: inloggen, schrijven en verwijderen werken; anoniem wordt geweigerd (`NT_STATUS_ACCESS_DENIED`); poort 445 is bereikbaar vanaf de laptop.
- Koppelen: Windows → `\192.168.1.203\Bestanden` als S:. iPhone (Bestanden) → `smb://192.168.1.203`. S24 (Mijn bestanden → Netwerkopslag → SMB).
- Ontdekt: de Windows-laptop stuurt thuisverkeer naar 192.168.1.x **via Tailscale** (subnetroutes geaccepteerd), dus via de kleine LXC 103. Dat kan de lage snelheid van de SSD-back-up verklaren (~3,5 MB/s).
- Nog te doen: de map `bestanden` meenemen in de SSD-back-up.
- Besluit eigenaar (2026-10-31): de map `bestanden` gaat **niet** naar de muziek-SSD; die SSD blijft vooral voor muziek (alleen de server-back-ups van ~8 GB, max. 3 sets). Back-up buiten huis via de cloud (bijvoorbeeld een Hetzner Storage Box met restic) is besproken, maar voor nu niet nodig.
- Let op: `bestanden` staat daardoor maar op **één schijf** (de 2 TB-NVMe). Zet daar geen bestanden die nergens anders staan, of kies alsnog een tweede plek.

## 2026-10-31: appdata automatisch in de wekelijkse back-up

- vzdump slaat bind mounts (zoals `appdata` van LXC 202) altijd over. Daarom een hook-script: `scripts/vzdump-appdata-hook.sh`, op de host in `/usr/local/bin/vzdump-appdata-hook.sh`.
- Het script wordt aangeroepen bij `job-start` van de wekelijkse taak (`script` in `/etc/pve/jobs.cfg`; reservekopie `/root/jobs.cfg.bak-2026-10-31`). Het stopt de apps in LXC 202, pakt `appdata` in (zonder de Plex-cache) naar `/mnt/nvme1n1/backups/appdata/appdata-JJJJ-MM-DD_UUMM.tar.gz`, start de apps weer en bewaart de laatste 4. Bij een fout gaat de rest van de back-up gewoon door.
- Test: 12 seconden onderbreking, archief van 32 MB met de databases van Radarr, Sonarr, Prowlarr en Bazarr en de instellingen van Overseerr. Alle 7 apps draaiden daarna weer.
- Het SSD-script pakt automatisch de nieuwste appdata-back-up mee.

## 2026-10-31: flow@pve en rpcbind uit, opgeruimd

- **`flow@pve`** (beheerder van de hele server, alleen een wachtwoord, geen logins in de bewaarde logboeken) is **uitgezet**, niet verwijderd. Terugzetten: `pveum user modify flow@pve --enable 1`.
- **`rpcbind`** (poort 111, alleen nodig voor NFS, dat niet gebruikt wordt) is gestopt en start niet meer automatisch. Poort 111 is dicht. Terugzetten: `systemctl enable --now rpcbind.socket rpcbind.service`.
- Opgeruimd: de oude back-up van 202 uit juni 2025 (403 MB in `/var/lib/vz/dump`) en `/root/docker-compose.yaml.bak-2026-10-30` in LXC 202 (bevatte het oude NZBGet-wachtwoord).
- Gecontroleerd: alle VM's/LXC's draaien, de 7 Docker-apps in 202 draaien, de Proxmox-webpagina werkt.
- `inventaris.md`: back-uptabel bijgewerkt (de wekelijkse taak neemt **alle** machines mee, `all 1`) en een tabel met Proxmox-gebruikers toegevoegd.

## 2026-10-31: Samba-map `bestanden` in de back-ups

- Besluit eigenaar: `bestanden` gaat nu **wel** mee, ook naar de SSD (dit vervangt het eerdere besluit hierboven).
- **Wekelijks (server)**: het hook-script `scripts/vzdump-appdata-hook.sh` kopieert bij de zondagse taak eerst `bestanden` met rsync naar `/var/lib/vz/bestanden-kopie/JJJJ-MM-DD_UUMMSS/` op de **500 GB-schijf** (het origineel staat op de 2 TB-schijf). 4 weekmappen; ongewijzigde bestanden zijn hardlinks en kosten maar één keer ruimte. Boven 50 GB, of als er minder dan 20 GB vrij zou blijven, slaat het de kopie over met een FOUT-melding in het back-uplogboek. Met de hand: `vzdump-appdata-hook.sh bestanden` op de host (de apps worden daarbij niet gestopt).
- Reservekopie van het oude hook-script: `/root/vzdump-appdata-hook.sh.bak-2026-10-31` op de host.
- **SSD**: `scripts/backup-naar-ssd.sh` zet nu ook één actuele kopie in `D:\Homelab\Back-ups\bestanden` (geen 3 datummappen, om ruimte te sparen), gecontroleerd met sha256 (`bestanden-sha256.txt`). Bij een fout blijft de vorige kopie staan.
- Getest: 5 runs op de server (4 bewaard, hardlinks werken), de 7 apps bleven draaien; SSD-run met een testbestand (met spatie in de naam) gecontroleerd OK, en na verwijderen verdween het ook van de SSD. Testbestanden opgeruimd.
- Grens: wordt `bestanden` groter dan 50 GB, dan moet er een andere plek voor de serverkopie komen.

## Op het lijstje (2026-10-31)
- Tweestapsverificatie (TOTP) op Proxmox voor `root@pam`: uitgesteld op verzoek van de eigenaar.

## 2026-10-31: vaste IP-adressen

- **Tailscale (103) → 192.168.1.204** en **Vaultwarden (104) → 192.168.1.205**: vast via `pct set ... ip=.../24,gw=192.168.1.1`. Getest: allebei online in Tailscale, internet en DNS werken, Vaultwarden antwoordt via https://vaultwarden.tailf6fed1.ts.net.
- **Zigbee-stick (SLZB-06) → 192.168.1.208**: door de eigenaar op de stick zelf ingesteld (DHCP uit, gateway 192.168.1.1). In Zigbee2MQTT `serial.port` aangepast naar `tcp://192.168.1.208:6638`.
- **Zigbee2MQTT (100) → 192.168.1.206**. In Home Assistant de MQTT-koppeling opnieuw geconfigureerd (via de API, wachtwoord ongewijzigd) met broker `192.168.1.206`. De titel van de koppeling toont nog "192.168.1.58"; dat is alleen een naam.
- Getest: HA is verbonden met Mosquitto op .206; na een herstart van Zigbee2MQTT hebben alle 25 lampen weer een status in HA. Niets opnieuw gekoppeld; namen en automatiseringen ongewijzigd. Onderbreking ongeveer 5 minuten.
- Reservekopieën: `/root/lxc-{100,103,104}.conf.bak-2026-10-31-ip` op de host, en in LXC 100 `/root/backup-2026-10-31-ip/` (configuration.yaml, database.db, coordinator_backup.json).
- Terugdraaien: `pct set <id> -net0 ...,ip=dhcp` (of de reservekopie terugzetten) en herstarten; stick weer op DHCP en het oude `serial.port` uit de reservekopie.
- **Home Assistant (101) houdt .184 (DHCP)**: overgeslagen op verzoek van de eigenaar. Nog te doen: in de router nakijken of .184 een vaste reservering heeft.
- Let op: de Zigbee2MQTT-webpagina staat nu op http://192.168.1.206:8080 (oude bladwijzers aanpassen).
