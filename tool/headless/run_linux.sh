#!/usr/bin/env bash
# Full headless test of the audio spike on Linux desktop:
#   - virtual display (Xvfb) so the real app window renders,
#   - virtual sound card (PulseAudio null sink) so audio really plays,
#   - the sink's output is recorded and analysed for silence and dropouts,
#   - screenshots of each UI step.
#
# Usage: tool/headless/run_linux.sh [test ...]   (default: ui_test spike_test)
# Output: build/headless/linux/ (logs, screenshots, recordings, summary.md)
#
# Needs: flutter, clang, cmake, ninja, libgtk-3-dev, xvfb, pulseaudio,
#        pulseaudio-utils, python3 + numpy.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
APP="$ROOT/apps/audio_spike"
OUT="$ROOT/build/headless/linux"
SECONDS_PER_SCENARIO="${SPIKE_SECONDS:-10}"
# Ask PulseAudio for low latency, as the real app must (otherwise Pulse gives
# a ~2 s buffer and playback starts 1-2 s late). Override to test defaults.
export PULSE_LATENCY_MSEC="${PULSE_LATENCY_MSEC-20}"
TESTS=("$@")
[ ${#TESTS[@]} -eq 0 ] && TESTS=(ui_test spike_test)

rm -rf "$OUT" && mkdir -p "$OUT/screenshots"

# Virtual display.
if [ -z "${DISPLAY:-}" ]; then
  export DISPLAY=:99
  if ! xdpyinfo -display "$DISPLAY" >/dev/null 2>&1; then
    Xvfb "$DISPLAY" -screen 0 1280x1024x24 >"$OUT/xvfb.log" 2>&1 &
    sleep 1
  fi
fi

# Virtual sound card.
if ! pactl info >/dev/null 2>&1; then
  pulseaudio -D --exit-idle-time=-1 --system=false 2>"$OUT/pulse.log" || true
  for _ in 1 2 3 4 5; do pactl info >/dev/null 2>&1 && break; sleep 1; done
fi
if ! pactl list short sinks | grep -q '^[0-9]*\s*spike\s'; then
  pactl load-module module-null-sink sink_name=spike rate=48000 channels=2 \
    sink_properties=device.description=spike >/dev/null
fi
pactl set-default-sink spike
# An idle sink is suspended and its monitor then delivers no samples at all,
# which would compress silences out of the recording. Keep it running.
pactl unload-module module-suspend-on-idle 2>/dev/null || true

status=0
summary="$OUT/summary.md"
echo "# Headless test: Linux desktop" >"$summary"

for t in "${TESTS[@]}"; do
  echo "== $t"
  rec="$OUT/$t.raw"
  log="$OUT/$t.log"
  parec -d spike.monitor --format=float32le --rate=48000 --channels=2 >"$rec" &
  rec_pid=$!
  rec_start=$(date +%s%3N)
  echo "$rec_start" >"$OUT/$t.rec_start_ms"
  set +e
  (cd "$APP" && flutter drive --profile -d linux \
    --dart-define=SHOT_DIR="$OUT/screenshots" \
    --dart-define=SPIKE_SECONDS="$SECONDS_PER_SCENARIO" \
    --driver=test_driver/integration_test.dart \
    --target="integration_test/$t.dart") >"$log" 2>&1
  rc=$?
  set -e
  sleep 0.5
  kill "$rec_pid" 2>/dev/null || true
  wait "$rec_pid" 2>/dev/null || true
  grep -E "All tests passed|Some tests failed|EXCEPTION|Error:" "$log" | tail -5 || true
  {
    echo
    echo "## $t (flutter drive exit $rc)"
    echo
    grep -o 'SPIKE_RESULT playback .*' "$log" | sed 's/^SPIKE_RESULT playback /- /' || true
    echo
  } >>"$summary"
  [ $rc -ne 0 ] && status=1
  # spike_test sweeps look-ahead down to 20 ms to find the floor, so its
  # audio is reported, not gated. Other tests must play cleanly.
  strict=()
  [ "$t" = spike_test ] && strict=(--report-only)
  if ! python3 "$ROOT/tool/headless/analyze_audio.py" "$rec" "$rec_start" "$log" "${strict[@]}" \
      --json "$OUT/$t.audio.json" >>"$summary"; then
    status=1
  fi
  [ -f "$APP/build/integration_response_data.json" ] &&
    mv "$APP/build/integration_response_data.json" "$OUT/$t.response.json"
  # Keep recordings small: compress to FLAC if ffmpeg is around.
  if command -v ffmpeg >/dev/null; then
    ffmpeg -loglevel error -y -f f32le -ar 48000 -ac 2 -i "$rec" "$OUT/$t.flac" && rm "$rec"
  fi
done

cp -r "$APP/build/screenshots/." "$OUT/screenshots/" 2>/dev/null || true
echo
cat "$summary"
exit $status
