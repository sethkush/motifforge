# Contributing to MotifForge

MotifForge is an open-source songwriting app that aims to work like
Hooktheory's Hookpad: same workflow, layout, shortcuts and musical results.
Everything in it (code, artwork, sounds, text, data, names) is made
independently. Read [`docs/PLAN.md`](docs/PLAN.md) for the full picture.

## Clean-room rules

These protect the project legally. A contribution that breaks them will be
removed.

1. **Don't copy Hookpad or Hooktheory material.** That covers code, help
   text, tooltips, icons, logos, artwork, fonts, sound samples, band or style
   patterns, templates, progressions lists and TheoryTab data. Don't decompile
   or inspect their client code, scrape their sites, or call their private
   APIs.
2. **Describe behaviour, then implement it.** Use Hookpad as an ordinary
   user (the public guide, screenshots, screen recordings) and write what it
   does **in your own words** in [`docs/spec/`](docs/spec/README.md). Tag
   every rule `documented`, `observed` or `assumed`, and add conformance
   cases. Code is written from the specs.
3. **Don't use their names** (Hookpad, Hooktheory, TheoryTab, Aria, Magic
   Chord) in the product, UI strings, identifiers or file names. Saying
   "imports Hookpad clipboard data" in docs is fine.
4. **Don't commit their documents**, such as the Hookpad user guide PDF, or
   long quotes from them.
5. **Same layout, our own look.** Match where things are and how they
   behave. Don't reproduce their exact colours, typography or icons.

## Licences

- Code is under the [ISC License](LICENSE). By contributing you agree to
  license your contribution under it.
- Every bundled asset (SoundFonts, samples, fonts, datasets, models) must be
  CC0, CC-BY, OFL, MIT or similarly permissive, and listed in
  [`assets/LICENSES.md`](assets/LICENSES.md) with source, licence and
  required attribution. No GPL/NC/ND assets.
- Vendored third-party code goes in `third_party/<name>/` with its licence
  file and a note on any changes.

## Development

Requires Flutter stable (which includes Dart ≥ 3.11). The repo is a Dart pub
workspace.

```sh
flutter pub get                                   # once, from the repo root
dart format packages tool apps/audio_spike/lib    # format
dart analyze --fatal-infos                        # lint (CI uses --fatal-infos)
dart test packages/motif_theory                   # one package
dart test packages/motif_theory/test/chord_tables_test.dart -N "applied"   # one test
dart test packages/motif_conformance              # spec conformance cases
(cd packages/motif_conformance && dart run motif_conformance:report)       # parity table
```

CI (`.github/workflows/ci.yml`) runs format, analyze, tests, the parity
report, and web builds (JS and Wasm) of the synth and the audio spike.

### Adding behaviour

1. Write or extend the rule in `docs/spec/<area>.md`, with a `conformance`
   block (format in [`docs/spec/README.md`](docs/spec/README.md)).
2. If it's a new `kind`, add a runner in
   `packages/motif_conformance/lib/src/runners.dart`.
3. Implement it, with unit tests in the owning package.
4. Check the parity report doesn't regress.
