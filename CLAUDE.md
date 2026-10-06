# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project status

MotifForge is an open-source Flutter/Dart clone of Hooktheory's Hookpad. You write melodies and chords as scale degrees and Roman numerals, a band plays them back, and you can export the song. `docs/PLAN.md` is the source of truth for scope, architecture and roadmap (milestones M0–M9); its M0 checklist shows what exists. Read the relevant section before you implement anything, and update the plan when a decision changes.

What exists so far (M0): `packages/motif_theory` (all theory), `packages/motif_conformance` (runs spec cases), `docs/spec/` (behaviour specs), `tool/audio_bench` + `apps/audio_spike` (audio spike, results in `docs/spikes/m0-audio.md`), and a patched vendored synth in `third_party/dart_melty_soundfont`.

## Commands

Dart pub workspace (root `pubspec.yaml`). Requires Flutter stable (Dart ≥ 3.11). Run from the repo root unless noted.

```sh
flutter pub get                                   # resolve the whole workspace
dart format packages tool apps/audio_spike/lib    # format (CI checks with --set-exit-if-changed)
dart analyze --fatal-infos                        # lint; third_party/ is excluded
dart test packages/motif_theory packages/motif_conformance tool/audio_bench   # all tests
dart test packages/motif_theory/test/chord_tables_test.dart -N "applied"      # single test by name
(cd packages/motif_conformance && dart run motif_conformance:report)          # parity table per spec
(cd tool/audio_bench && dart run audio_bench:bench [file.sf2])                # synth benchmark
(cd apps/audio_spike && flutter build web --wasm --no-web-resources-cdn)      # spike app web build
```

Headless end-to-end testing (real app, virtual display, virtual sound card, recorded output analysed for dropouts; see `docs/spikes/m0-audio.md`):

```sh
tool/headless/run_linux.sh                 # Linux desktop: UI test + audio measurements
tool/headless/run_web.sh                   # Chromium via Playwright (needs PLAYWRIGHT_MODULE, DISPLAY)
tool/headless/run_android.sh [secs] [dev]  # Android emulator/device
```

Results land in `build/headless/<platform>/` (summary.md, logs, screenshots, FLAC). Screenshots can be viewed with the Read tool. In this container, first start `Xvfb :99` and set `DISPLAY=:99`; the scripts start PulseAudio themselves. Never use `pkill -f` with a pattern that also appears in your own command line: it kills the calling shell (exit 144).

CI (`.github/workflows/ci.yml`) runs format, analyze, tests and the parity report, and compiles the synth to JS and Wasm. The JS build matters: Flutter web always builds a JS fallback.

## Clean-room rules (non-negotiable)

The goal is behavioural parity with Hookpad: same layout, same default shortcuts, same entry rules, same playback results. It must stay legal (see `docs/PLAN.md` §0):
- **Never** copy Hookpad/Hooktheory code, help text, icons, artwork, fonts, sound samples, style patterns or TheoryTab data. Don't decompile their client, scrape their site or call their private APIs.
- **Never** use their names (Hookpad, Hooktheory, TheoryTab, Aria, Magic Chord) in product or feature names, UI strings or identifiers. Use our own names, e.g. "Suggest Chord".
- Behaviour specs go in `docs/spec/<area>.md`, in our own words. Every rule is tagged `documented` / `observed` / `assumed`, and examples go in fenced `conformance` YAML blocks (format: `docs/spec/README.md`). `packages/motif_conformance` runs them; kinds without a runner (e.g. `edit`, until `motif_core` exists) are skipped as pending. When you change theory behaviour, update the spec cases too. When an `assumed` rule gets checked against Hookpad, retag it.
- Don't commit the Hookpad User Guide PDF, or text quoted from it.
- Code is ISC (`LICENSE`). Every bundled asset (SoundFonts, fonts, datasets, models) must be CC0, CC-BY, OFL or MIT-compatible and recorded in `assets/LICENSES.md`. Each dataset's source and licence also goes in `assets/models/README.md`.

## Architecture (planned)

Layering: `motif_theory` → `motif_core` → `motif_engine` → `motif_io` / `motif_suggest`. Each of these is **pure Dart with no Flutter imports**, so it can be tested quickly and reused on the server. Only `motif_audio` and `apps/motifforge` depend on Flutter or plugins.

Design decisions that span packages:
- **Theory conventions** (`motif_theory`): octave 0 means the tonic at or above middle C (C4 = MIDI 60). Spelling is letter-based (tonic letter + degree − 1). Chord extensions and add-tones stack scale tones; sus uses a major 2nd / perfect 4th; alterations are absolute intervals; applied V/IV use the target's major scale and vii uses its harmonic minor. Several of these are `assumed` in the specs.
- **Notes and chords are stored relative to the key** (scale degree + accidental + octave; chords as degree + type, inversion, sus, add/omit, alterations, applied, borrowed). Absolute pitch is computed at render time from the key in force at that tick. Parallel and relative key changes are therefore model transforms, not re-pitching. Spelling follows the degree: ♯2 in C is D♯, never E♭.
- **Time is integer ticks, `ticksPerBeat = 480`.** A "beat" is the *meter* beat. With beat unit 3 (compound meters) it maps to an eighth note in MIDI and notation, otherwise to a quarter. Keys, meters, tempi and bands are maps keyed by measure index. Swing is applied in the engine, never stored on notes.
- **Edits are pure `Song → Song` functions**, wrapped in labelled `Command`s and run against an `EditContext` (Table/Text entry mode, Smart Octave, sticky palette state). Undo is a snapshot stack of immutable `Song`s (default depth 20, to match Hookpad).
- **The arrangement engine is deterministic**: `render(Song, range) → PerformanceEvent`s. Harmony, bass and drum styles are data files (`assets/styles`, `assets/drums`), not code. Snapshot tests check `song.json → events.json`.
- **Audio**: we synthesise everything ourselves from SoundFonts with `dart_melty_soundfont`, overridden to the patched copy in `third_party/` because upstream 2.0.0 doesn't compile for the web. Rendering goes in an isolate on native; a web backend sits behind the same interface. The playhead comes from frames actually played, not from timers. The output plugin is provisionally `mp_audio_stream`; device measurements are still open (`docs/spikes/m0-audio.md`).
- **UI**: Riverpod state. The score is drawn by custom painters, one per line ("system"), with typed hit targets (note body, inner edge, outer edge, chord, flag, measure). A central `KeymapService` tracks *held* keys, because entry depends on them: ↑/↓ or `.`/`,` held while typing a digit.
- **Interop**: we always read Hookpad's clipboard JSON (`sd`, `octave`, `beat`, `duration`, `isRest`, `fp`). The native file format is versioned JSON (`*.motif`) with a migration chain.

## Environment note

The cloud environment's network policy blocks `hooktheory.com`. Hookpad reference material (the guide, a shortcuts page, screenshots) has to come from the user. The gaps still open are listed in `docs/PLAN.md` §0.5.

For headless runs the container also needs: `apt-get install libgtk-3-dev pulseaudio pulseaudio-utils` (clang, cmake, ninja, Xvfb, ffmpeg, numpy are preinstalled). Playwright lives at `/opt/node-tools/node_modules/playwright`, with Chromium in `/opt/pw-browsers`. Android can't build here (the Android SDK download host is blocked), so Android runs in CI (`android.yml`); read results with the GitHub MCP tools (`actions_list`, `get_job_logs`).

The cloud container doesn't ship Flutter. Install the stable tarball listed in `https://storage.googleapis.com/flutter_infra_release/releases/releases_linux.json` into `/opt/flutter`, run `git config --global --add safe.directory /opt/flutter`, and add `/opt/flutter/bin` to `PATH`. GitHub and gstatic are blocked, so web builds need `--no-web-resources-cdn`.
