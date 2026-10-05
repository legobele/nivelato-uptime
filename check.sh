#!/bin/bash
# Nivelato uptime probe. Run every 15 min via GitHub Actions.
# Appends a check to checks.jsonl, regenerates status.json, pushes to GitHub.
# Prints FLIP:up / FLIP:down / SAME:<status> for the cron wrapper.
set -u
DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$DIR" || exit 1

probe() { # url, content-match -> "up code ms"
  local url=$1 match=$2
  local body out code secs ms up
  body=$(mktemp)
  out=$(curl -sL -m 25 -o "$body" -w "%{http_code} %{time_total}" "$url" 2>/dev/null || echo "000 0")
  code=$(echo "$out" | awk '{print $1}')
  secs=$(echo "$out" | awk '{print $2}')
  ms=$(python3 -c "print(int(float('$secs')*1000))" 2>/dev/null || echo 0)
  up=false
  if [ "$code" = "200" ] && grep -qi "$match" "$body"; then up=true; fi
  rm -f "$body"
  echo "$up $code $ms"
}

TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
read -r L_UP L_CODE L_MS <<< "$(probe "https://login.nivelatolabs.com/" "nivelato")"
read -r A_UP A_CODE A_MS <<< "$(probe "https://app.nivelatolabs.com/" "nivelato")"
read -r P_UP P_CODE P_MS <<< "$(probe "https://nivelato.pages.dev/" "nivelato")"

PREV="unknown"
[ -f .prev_status ] && PREV=$(cat .prev_status)

python3 gen.py "$TS" "$L_UP" "$L_CODE" "$L_MS" "$A_UP" "$A_CODE" "$A_MS" \
  "$P_UP" "$P_CODE" "$P_MS"

echo "$([ "$L_UP" = "true" ] && echo up || echo down)" > .prev_status
git add -A >/dev/null 2>&1
git commit -qm "check $TS login=$L_UP app=$A_UP pages=$P_UP" >/dev/null 2>&1
git push -q origin main >/dev/null 2>&1

NOW="$([ "$L_UP" = "true" ] && echo up || echo down)"
if [ "$PREV" != "$NOW" ] && [ "$PREV" != "unknown" ]; then
  echo "FLIP:$NOW"
else
  echo "SAME:$NOW"
fi
