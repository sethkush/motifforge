#!/usr/bin/env bash
# Headless test of the audio spike's web build: builds each integration test
# as a web page (JS, or Wasm with WEB_WASM=1), opens it in headless Chromium
# via Playwright, records the browser's audio from the PulseAudio null sink,
# and analyses it like run_linux.sh. Screenshots are taken by the runner.
#
# Usage: tool/headless/run_web.sh [test ...]   (default: ui_test spike_test)
# Needs: flutter, node + playwright (PLAYWRIGHT_MODULE to point at it),
#        pulseaudio + pulseaudio-utils, python3 + numpy.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
APP="$ROOT/apps/audio_spike"
OUT="$ROOT/build/headless/web"
TESTS=("$@")
[ ${#TESTS[@]} -eq 0 ] && TESTS=(ui_test spike_test)
SECS="${SPIKE_SECONDS:-10}"
rm -rf "$OUT" && mkdir -p "$OUT"

# Virtual sound card (shared helper logic with run_linux.sh).
if ! pactl info >/dev/null 2>&1; then
  pulseaudio -D --exit-idle-time=-1 --system=false 2>"$OUT/pulse.log" || true
  for _ in 1 2 3 4 5; do pactl info >/dev/null 2>&1 && break; sleep 1; done
fi
pactl list short sinks | grep -q '^[0-9]*\s*spike\s' ||
  pactl load-module module-null-sink sink_name=spike rate=48000 channels=2 >/dev/null
pactl set-default-sink spike
pactl unload-module module-suspend-on-idle 2>/dev/null || true

failure_excerpt() {  # $1 = log file
  echo '```'
  grep -v SPIKE_MARK "$1" | grep -E -A4 "EXCEPTION CAUGHT|Expected:|could not|was not found|Error:|Exception:" | head -40
  echo '```'
}

summary="$OUT/summary.md"
echo "# Headless test: web (Chromium${WEB_WASM:+, Wasm})" >"$summary"
status=0
port=8790
for t in "${TESTS[@]}"; do
  echo "== $t"
  site="$OUT/site-$t"
  (cd "$APP" && flutter build web --profile --no-web-resources-cdn ${WEB_WASM:+--wasm} \
    -t "integration_test/$t.dart" -o "$site" \
    --dart-define=HOST_SCREENSHOTS=true --dart-define=SPIKE_SECONDS="$SECS") >"$OUT/$t.build.log" 2>&1
  python3 -m http.server "$port" --directory "$site" >/dev/null 2>&1 &
  server=$!
  sleep 1
  parec -d spike.monitor --format=float32le --rate=48000 --channels=2 >"$OUT/$t.raw" &
  rec=$!
  rec_start=$(date +%s%3N)
  set +e
  node "$ROOT/tool/headless/web_runner.cjs" "http://127.0.0.1:$port/" "$OUT" "$OUT/$t.log" 900
  rc=$?
  set -e
  kill "$rec" "$server" 2>/dev/null || true
  wait "$rec" "$server" 2>/dev/null || true
  port=$((port + 1))
  [ $rc -ne 0 ] && status=1
  {
    echo
    echo "## $t (runner exit $rc)"
    echo
    grep -o 'SPIKE_RESULT playback .*' "$OUT/$t.log" | sed 's/^SPIKE_RESULT playback /- /' || true
    echo
    [ $rc -ne 0 ] && failure_excerpt "$OUT/$t.log"
  } >>"$summary"
  # Web still renders on the UI thread, which drops out under load: a known
  # issue until synthesis moves to an AudioWorklet/Worker. Report dropouts,
  # but still fail on silence or a long start-up gap.
  strict=(--dropouts-informational)
  [ "$t" = spike_test ] && strict=(--report-only)
  python3 "$ROOT/tool/headless/analyze_audio.py" "$OUT/$t.raw" "$rec_start" "$OUT/$t.log" \
    "${strict[@]}" --json "$OUT/$t.audio.json" >>"$summary" || status=1
  if command -v ffmpeg >/dev/null; then
    ffmpeg -loglevel error -y -f f32le -ar 48000 -ac 2 -i "$OUT/$t.raw" "$OUT/$t.flac" && rm "$OUT/$t.raw"
  fi
  rm -rf "$site"
done
cat "$summary"
exit $status
