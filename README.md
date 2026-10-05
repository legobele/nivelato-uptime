# Nivelato uptime tracker

Unofficial status monitor for the Nivelato web properties, probed every 15 minutes.
Pattern copied from `legobele/isinetc-status`.

## Targets

| key | name | url | check |
|-----|------|-----|-------|
| login | Login (login.nivelatolabs.com) | https://login.nivelatolabs.com/ | HTTP 200 + page mentions "nivelato" |
| app | App (app.nivelatolabs.com) | https://app.nivelatolabs.com/ | HTTP 200 + page mentions "nivelato" |
| pages | Hosting (Cloudflare Pages) | https://nivelato.pages.dev/ | HTTP 200 + page mentions "nivelato" |

## How it works

1. `check.sh` probes each URL with curl (25s timeout), passes results to `gen.py`.
2. `gen.py` appends to `checks.jsonl` (90-day rolling window), regenerates `status.json`
   with per-target status, uptime percentages, daily bars, and incident detection.
3. The workflow commits and pushes; GitHub Pages serves `index.html` + `status.json`.
4. `index.html` renders the dashboard from `status.json` and hosts the user report form.

## User reports

The "Report an outage" form writes to the Firestore collection `uptime_reports`
(project `nivelato-app`). Recent reports render anonymized on the page (site + text
only, no contact shown).

### Setup needed before going live

1. **Firebase API key:** `index.html` has `apiKey: "FIREBASE_API_KEY"` as a placeholder.
   Replace it with the web API key from `firebase-config.js` in the nivelato repo
   (same value used by login.html; it is a public client key).
2. **Firestore rules:** publish `firestore.rules` (or merge the `uptime_reports`
   block into the existing rules for `nivelato-app`).
3. **Repo:** create `legobele/nivelato-uptime` on GitHub, push this directory,
   enable GitHub Pages (Deploy from branch, `main`, root).
4. **Watchdog:** no extra secrets needed (`GITHUB_TOKEN` is automatic).

## Files

- `index.html` — status dashboard + report form (dark Nivelato theme)
- `check.sh` — probe script (run by Actions every 15 min)
- `gen.py` — appends to `checks.jsonl`, regenerates `status.json`
- `status.json` — generated (do not hand-edit)
- `checks.jsonl` — generated append-only log
- `firestore.rules` — security rules for `uptime_reports`
- `.github/workflows/probe.yml` — 15-min probe
- `.github/workflows/watchdog.yml` — hourly freshness watchdog, re-dispatches the probe if stale
