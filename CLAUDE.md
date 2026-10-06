# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project status

MotifForge is an open-source Flutter/Dart clone of Hooktheory's Hookpad. You write melodies and chords as scale degrees and Roman numerals, a band plays them back, and you can export the song. **There's no code yet.** The repo holds only the plan. `docs/PLAN.md` is the source of truth for scope, architecture and roadmap (milestones M0–M9). Read the relevant section before you implement anything, and update the plan when a decision changes.

## Commands

No workspace or CI exists yet. The plan is a Dart ≥3.6 pub workspace: pure-Dart packages in `packages/`, the Flutter app in `apps/motifforge/`. These are the standard tools for that layout:

```sh
dart pub get                                   # from repo root (workspace resolution)
dart analyze                                   # lint everything
dart format .                                  # format
dart test packages/motif_theory                # tests for one pure-Dart package
dart test packages/motif_theory/test/foo_test.dart -N "name substring"   # single test
cd apps/motifforge && flutter test             # Flutter/widget/golden tests
cd apps/motifforge && flutter run -d chrome    # run the app (web is a primary target)
```

When the workspace, lints and CI (analyse + test + web build) land in M0, update this section with the actual commands.

## Clean-room rules (non-negotiable)

The goal is behavioural parity with Hookpad: same layout, same default shortcuts, same entry rules, same playback results. It must stay legal (see `docs/PLAN.md` §0):
- **Never** copy Hookpad/Hooktheory code, help text, icons, artwork, fonts, sound samples, style patterns or TheoryTab data. Don't decompile their client, scrape their site or call their private APIs.
- **Never** use their names (Hookpad, Hooktheory, TheoryTab, Aria, Magic Chord) in product or feature names, UI strings or identifiers. Use our own names, e.g. "Suggest Chord".
- Behaviour specs go in `docs/spec/<area>.md`, in our own words, each with conformance cases (starting state + input sequence → expected result). Those cases become tests in `test/conformance/`, and that suite is how we measure parity.
- Don't commit the Hookpad User Guide PDF, or text quoted from it.
- Code is ISC (`LICENSE`). Every bundled asset (SoundFonts, fonts, datasets, models) must be CC0, CC-BY, OFL or MIT-compatible and recorded in `assets/LICENSES.md`. Each dataset's source and licence also goes in `assets/models/README.md`.

## Architecture (planned)

Layering: `motif_theory` → `motif_core` → `motif_engine` → `motif_io` / `motif_suggest`. Each of these is **pure Dart with no Flutter imports**, so it can be tested quickly and reused on the server. Only `motif_audio` and `apps/motifforge` depend on Flutter or plugins.

Design decisions that span packages:
- **Notes and chords are stored relative to the key** (scale degree + accidental + octave; chords as degree + type, inversion, sus, add/omit, alterations, applied, borrowed). Absolute pitch is computed at render time from the key in force at that tick. Parallel and relative key changes are therefore model transforms, not re-pitching. Spelling follows the degree: ♯2 in C is D♯, never E♭.
- **Time is integer ticks, `ticksPerBeat = 480`.** A "beat" is the *meter* beat. With beat unit 3 (compound meters) it maps to an eighth note in MIDI and notation, otherwise to a quarter. Keys, meters, tempi and bands are maps keyed by measure index. Swing is applied in the engine, never stored on notes.
- **Edits are pure `Song → Song` functions**, wrapped in labelled `Command`s and run against an `EditContext` (Table/Text entry mode, Smart Octave, sticky palette state). Undo is a snapshot stack of immutable `Song`s (default depth 20, to match Hookpad).
- **The arrangement engine is deterministic**: `render(Song, range) → PerformanceEvent`s. Harmony, bass and drum styles are data files (`assets/styles`, `assets/drums`), not code. Snapshot tests check `song.json → events.json`.
- **Audio**: we synthesise everything ourselves from SoundFonts (pure-Dart synth, in an isolate on native; a web backend sits behind the same interface). The playhead comes from frames actually played, not from timers. The output plugin hasn't been chosen; the M0 audio spike decides it.
- **UI**: Riverpod state. The score is drawn by custom painters, one per line ("system"), with typed hit targets (note body, inner edge, outer edge, chord, flag, measure). A central `KeymapService` tracks *held* keys, because entry depends on them: ↑/↓ or `.`/`,` held while typing a digit.
- **Interop**: we always read Hookpad's clipboard JSON (`sd`, `octave`, `beat`, `duration`, `isRest`, `fp`). The native file format is versioned JSON (`*.motif`) with a migration chain.

## Environment note

The cloud environment's network policy blocks `hooktheory.com`. Hookpad reference material (the guide, a shortcuts page, screenshots) has to come from the user. The gaps still open are listed in `docs/PLAN.md` §0.5.
