# Inventaris homelab

Laatst bijgewerkt: 2026-10-30

## Mini-pc (Proxmox-host)

| | |
|---|---|
| Processor | AMD Ryzen 7 5825U (8 kernen / 16 threads) met Radeon-videochip |
| Geheugen | 27 GB |
| IP-adres | 192.168.1.201 (webpagina: https://192.168.1.201:8006) |
| Besturingssysteem | Proxmox VE 8.4.21, kernel 6.8.12-43 |
| Netwerk | via kabel (`eno1` → brug `vmbr0`) |
| SSH vanaf laptop | sleutel `~/.ssh/proxmox_claude` (als root) |

### Schijven

| Schijf | Grootte | Waarvoor | Pad op host |
|---|---|---|---|
| nvme1n1 | 500 GB | Proxmox zelf, back-ups (`local`) en schijven van VM/LXC's (`local-lvm`) | `/`, `/var/lib/vz` |
| nvme0n1 | 2 TB | Media, downloads en instellingen van de arr-stack | `/mnt/nvme1n1` (let op: de naam klopt niet met de schijf, maar werkt) |

## Virtuele machines en containers

| ID | Naam | Soort | IP | Kernen | Geheugen | Schijf | Start automatisch |
|---|---|---|---|---|---|---|---|
| 101 | home-assistant | VM (Home Assistant OS) | 192.168.1.184 (DHCP) | 2 | 6 GB | 32 GB | ja |
| 100 | zigbee2mqtt | LXC (Debian) | 192.168.1.58 (DHCP) | 2 | 1 GB | 8 GB (30% vol) | ja |
| 202 | servarr | LXC (Ubuntu 22.04 + Docker, privileged, videochip doorgegeven) | 192.168.1.202 (vast) | 6 | 2 GB | 24 GB | ja |
| 103 | tailscale | LXC (Debian 12, unprivileged, `/dev/net/tun`) | 192.168.1.170 (DHCP), Tailscale 100.90.115.11 | 1 | 256 MB | 2 GB | ja |
| 104 | vaultwarden | LXC (Debian 12 + Docker, unprivileged, eigen Tailscale) | 192.168.1.158 (DHCP), Tailscale 100.86.0.87 | 1 | 512 MB | 4 GB | ja |

## Diensten

| Dienst | Waarvoor | Adres | Waar draait het | Instellingen / data |
|---|---|---|---|---|
| Home Assistant | slim huis | http://192.168.1.184:8123 | VM 101 | in de VM |
| Zigbee2MQTT | Zigbee-apparaten (Hue-lampen) | in LXC 100 | LXC 100 | `/opt/zigbee2mqtt/data` |
| Zigbee-stick | coördinator via netwerk (zstack) | tcp://192.168.1.165:6638 | los apparaat | - |
| Mosquitto | MQTT-berichten tussen Zigbee2MQTT en HA | in LXC 100 | LXC 100 | - |
| Plex | films/series kijken | http://192.168.1.202:32400/web | LXC 202 (Docker, host-netwerk) | `diensten/plex/docker-compose.yml` |
| Radarr | films zoeken | http://192.168.1.202:7878 | LXC 202 (Docker) | `diensten/servarr/docker-compose.yml` |
| Sonarr | series zoeken | http://192.168.1.202:8989 | LXC 202 (Docker) | idem |
| Prowlarr | zoekbronnen (indexers) | http://192.168.1.202:9696 | LXC 202 (Docker) | idem |
| NZBGet | downloaden | http://192.168.1.202:6789 | LXC 202 (Docker) | idem |
| Bazarr | ondertitels | http://192.168.1.202:6767 | LXC 202 (Docker) | idem |
| Overseerr | verzoeken voor films/series (gekoppeld aan Plex, Radarr, Sonarr) | http://192.168.1.202:5055 | LXC 202 (Docker) | idem |
| Tailscale | veilige toegang van buitenaf (subnet router voor 192.168.1.0/24) | machine "thuis-toegang" in tailnet `tailf6fed1.ts.net` | LXC 103 | sleutel verloopt niet |
| Vaultwarden | password manager (Bitwarden-apps, "zelf gehost") | https://vaultwarden.tailf6fed1.ts.net (**alleen via Tailscale**) | LXC 104 (Docker) | `/opt/vaultwarden/data`, `diensten/vaultwarden/docker-compose.yml` |

Van buitenaf: Tailscale-app aanzetten op het apparaat, en dan gewoon de 192.168.1.x-adressen hierboven gebruiken. Er staan geen poorten open op de router.

### Mappen van de arr-stack

| Op de host | In LXC 202 | In de Docker-containers |
|---|---|---|
| `/mnt/nvme1n1/servarr/appdata` | `/mnt/appdata` | `/config` (per app een eigen map) |
| `/mnt/nvme1n1/servarr/media` | `/mnt/media` | `/movies`, `/series` |
| `/mnt/nvme1n1/servarr/downloads` | `/mnt/downloads` | `/downloads` (NZBGet: `completed`, `intermediate`) |

De Docker-bestanden staan op de server in `/mnt/appdata/yaml` (arr-stack) en `/mnt/appdata/plexyaml` (Plex).

## Back-ups

| Wat | Waar | Wanneer |
|---|---|---|
| 100, 101, 202 | `backup2tb` (`/mnt/nvme1n1/backups`, op de 2 TB-schijf) | **automatisch elke zondag 03:00**, snapshot, de laatste 4 bewaard |
| 100, 101, 202 | `local` (`/var/lib/vz/dump`, op de 500 GB-schijf) | handmatig, 2026-10-30 |
| 202 (oud) | idem | handmatig, 2025-06-07 |

De back-ups staan op een andere schijf dan de VM's, maar nog wel in dezelfde mini-pc. Een kopie **buiten huis** is er nog niet.
