# Asset licence ledger

Every file shipped in the app or used to build it that isn't our own code
gets a row here: what it is, where it came from, its licence, and the
attribution we must show. Only permissive licences (CC0, CC-BY, OFL, MIT,
similar). No GPL, NC or ND.

## Bundled assets

| Asset | Path | Source | Licence | Attribution required |
|---|---|---|---|---|
| *(none yet)* | | | | |

## Vendored code

| Component | Path | Source | Licence | Notes |
|---|---|---|---|---|
| dart_melty_soundfont 2.0.0 (patched) | `third_party/dart_melty_soundfont` | pub.dev/packages/dart_melty_soundfont (port of MeltySynth) | MIT | Web build fixes, see `MOTIFFORGE_PATCHES.md` |

## Generated test assets

| Asset | Path | Notes |
|---|---|---|
| Synthetic benchmark SoundFont | `tool/audio_bench/lib/synthetic_sf2.dart` | Generated in code at runtime; no third-party content |

## Candidates under evaluation (not yet bundled)

| Asset | Licence (to confirm) | For |
|---|---|---|
| Salamander Grand Piano | CC-BY 3.0 | Piano sounds |
| VSCO 2 Community Edition | CC0 | Orchestral sounds |
| FluidR3_GM | MIT | General-MIDI fallback sounds |
| MuseScore_General | MIT | General-MIDI fallback sounds |
| Bravura / Leland (SMuFL) | OFL | Notation font for PDF export |
| ChoCo chord corpus | CC BY 4.0 | Chord-suggestion model |
