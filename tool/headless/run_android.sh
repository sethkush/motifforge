#!/usr/bin/env bash
# Headless test of the audio spike on a connected Android device or emulator
# (CI starts one with reactivecircus/android-emulator-runner). Runs the UI
# test (with screenshots) and the measurement test in profile mode.
#
# Usage: tool/headless/run_android.sh [seconds-per-scenario] [device-id]
# Output: build/headless/android/ (logs, screenshots, summary.md)
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
APP="$ROOT/apps/audio_spike"
OUT="$ROOT/build/headless/android"
SECS="${1:-20}"
DEVICE="${2:-emulator-5554}"
rm -rf "$OUT" && mkdir -p "$OUT/screenshots"
failure_excerpt() {  # $1 = log file
  echo '```'
  grep -v SPIKE_MARK "$1" | grep -E -A4 "EXCEPTION CAUGHT|Expected:|could not|was not found|Error:|Exception:" | head -40
  echo '```'
}

summary="$OUT/summary.md"
echo "# Headless test: Android ($DEVICE)" >"$summary"
status=0

for t in ui_test spike_test; do
  echo "== $t"
  (cd "$APP" && rm -rf build/screenshots && flutter drive --profile -d "$DEVICE" \
    --dart-define=SPIKE_SECONDS="$SECS" \
    --driver=test_driver/integration_test.dart \
    --target="integration_test/$t.dart") >"$OUT/$t.log" 2>&1
  rc=$?
  tail -5 "$OUT/$t.log"
  [ $rc -ne 0 ] && status=1
  cp -r "$APP/build/screenshots/." "$OUT/screenshots/" 2>/dev/null || true
  [ -f "$APP/build/integration_response_data.json" ] &&
    mv "$APP/build/integration_response_data.json" "$OUT/$t.response.json"
  {
    echo
    echo "## $t (flutter drive exit $rc)"
    echo
    [ $rc -ne 0 ] && failure_excerpt "$OUT/$t.log"
  } >>"$summary"
done

# The full report comes from the driver's response file: logcat truncates
# long lines, so the printed SPIKE_RESULT report can be cut off.
python3 - "$OUT/spike_test.response.json" >>"$summary" <<'PY'
import json, sys
try:
    r = json.load(open(sys.argv[1]))
except (FileNotFoundError, ValueError):
    print("No measurement report found; see spike_test.log."); sys.exit()
print(f"{r['platform']}, {r['secondsPerScenario']} s per scenario\n")
print("| Look-ahead ms | Stress | FX | Init | Load % | Peak chunk ms | Underruns | Start delay ms |")
print("|---|---|---|---|---|---|---|---|")
for p in r["playback"]:
    print(f"| {p['lookaheadMs']} | {p['stressVoices']} | {p['effects']} | {p['initResult']} | "
          f"{p['loadPercent']} | {p['peakChunkMs']} | {p['underruns']} | {p.get('startDelayMs')} |")
print("\n| CPU benchmark | Realtime factor | p99 chunk ms |\n|---|---|---|")
for b in r["benchmark"]:
    print(f"| {b['scenario']} | {b['realTimeFactor']}x | {b['p99ChunkMs']} |")
PY
ls "$OUT/screenshots" | sed 's/^/screenshot: /' >>"$summary"
cat "$summary"
exit $status
