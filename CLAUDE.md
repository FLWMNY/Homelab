# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

A beginner's first practice project: small, self-contained web pages (plain HTML/CSS/JS, no build step, no dependencies). Open an `.html` file directly in a browser to run it.

## Working with the owner

- The owner is new to AI and programming and writes in Dutch. Reply in Dutch, in plain language, and explain what each step does and why.
- Commit after every change that works, with a short Dutch commit message, so "go back to the last commit" is always an option.

## Git

- Git is installed at `C:\Program Files\Git\cmd\git.exe`. If `git` is not on PATH in the shell (e.g. the app was not restarted after installing), call it by that full path.
- Default branch is `main`; author name/email are set in this repo's local config.
- Remote `origin` is the private repo https://github.com/FLWMNY/Homelab (login via Git Credential Manager). Push after committing.
- The project lives on `D:\Claude`, which does not record file ownership; it is trusted via a global `safe.directory` entry for `D:/Claude/*`.
