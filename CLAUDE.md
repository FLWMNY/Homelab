# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

A beginner's first practice project: small, self-contained web pages (plain HTML/CSS/JS, no build step, no dependencies). Open an `.html` file directly in a browser to run it.

This repo is also the logbook of the owner's homelab (Proxmox mini-pc): `inventaris.md` (what runs where), `notities.md` (what was done, problems and fixes, with dates) and `diensten/<naam>/docker-compose.yml`. Never commit passwords or keys; they belong in `.env` (gitignored).

## Working with the owner

- The owner is new to AI and programming and writes in Dutch. Reply in Dutch, in plain language, and explain what each step does and why.
- Commit after every change that works, with a short Dutch commit message, so "go back to the last commit" is always an option.
- **Before changing or deleting anything** (server, apps, router, repo): first give a short step plan (who does what, what the owner will notice) and wait for an explicit "yes". Make a backup copy before risky changes and say how to roll back.
- Never ask for or put passwords, tokens or keys in the chat. The owner types passwords themselves; secrets Claude generates go into `.env`. Don't log in anywhere with a password on the owner's behalf.

## Homelab access

- Start of a session: read `notities.md` (history + "Nog te doen") and `inventaris.md` (what runs where, fixed IPs) before doing anything.
- Proxmox host: `ssh -i ~/.ssh/proxmox_claude root@192.168.1.201` (key-only SSH). Containers via `pct exec <id> -- ...`; the HA VM is 101.
- `.env` (gitignored) holds `HA_TOKEN` (Home Assistant API, http://192.168.1.184:8123), `MQTT_HA_USER`/`MQTT_HA_PASSWORD` and `SMB_USER`/`SMB_PASSWORD`. Read values from the file; never print them.
- Router (Odido/Zyxel, 192.168.1.1): DHCP hands out .2–.200; .201+ are fixed addresses. Only the owner logs into the router.
- Remote access is only via Tailscale (no open router ports, UPnP off). Vaultwarden is reachable only at https://vaultwarden.tailf6fed1.ts.net.
- Backups: weekly Proxmox job (Sun 03:00, `backup2tb` on the 2 TB disk, incl. appdata via hook) and `scripts/backup-naar-ssd.sh` to the external SSD `D:\Homelab\Back-ups` (that SSD is mainly for music; keep backups small).

## Git

- Git is installed at `C:\Program Files\Git\cmd\git.exe`. If `git` is not on PATH in the shell (e.g. the app was not restarted after installing), call it by that full path.
- Default branch is `main`; author name/email are set in this repo's local config.
- Remote `origin` is the private repo https://github.com/FLWMNY/Homelab (login via Git Credential Manager). Push after committing.
- The project lives on `D:\Claude`, which does not record file ownership; it is trusted via a global `safe.directory` entry for `D:/Claude/*`.
