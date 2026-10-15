#!/usr/bin/env bash
# Compiles the web audio engine's Web Worker (apps/audio_spike/worker/
# synth_worker.dart) to apps/audio_spike/web/synth_worker.js. Flutter's web
# build only compiles lib/main.dart, so run this before `flutter build web`
# or `flutter run -d chrome`.
set -euo pipefail
APP="$(cd "$(dirname "$0")/../apps/audio_spike" && pwd)"
cd "$APP"
dart compile js -O2 --no-source-maps worker/synth_worker.dart -o web/synth_worker.js
rm -f web/synth_worker.js.deps
