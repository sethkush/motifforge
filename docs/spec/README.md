# Behaviour specs

These files describe, **in our own words**, how MotifForge must behave so a
Hookpad user's muscle memory carries over. They are the clean-room boundary:
implementers work from these specs, never from Hookpad's code, text or assets
(see `docs/PLAN.md` §0 and `CONTRIBUTING.md`).

| File | Covers |
|---|---|
| [melody.md](melody.md) | Note entry, octave placement, selection, pitch/duration editing, split/tie, accidentals, voices, triplets |
| [chords.md](chords.md) | Chord entry, palette, inversions, types, sus/add/omit/alterations, applied and borrowed chords, labels |
| [structure.md](structure.md) | Measures, keys and scale changes, meter, tempo, looping, line breaks |
| [display.md](display.md) | Colour schemes, primary labels, staff spacing, chord compatibility guides |
| [keymap.md](keymap.md) | Default keyboard bindings |

## Rules and sources

Each rule has an id (`MEL-3`) and a source tag:

- **documented**: stated in the public Hookpad user guide.
- **observed**: seen by a person using Hookpad; note how in the case's `source`.
- **assumed**: our best guess. Must be checked against Hookpad before release; when it is, change the tag and fix the rule if needed.

## Conformance cases

Machine-checkable examples live in fenced blocks tagged `conformance`, written
in YAML. `packages/motif_conformance` extracts every block and runs it:

```sh
dart test packages/motif_conformance           # run all cases
dart run motif_conformance:report              # parity summary per spec / kind / status
```

Every block has:

```yaml
id: chords.diatonic-major      # unique, <file>.<topic>
kind: chord                    # selects the runner (below)
status: documented             # documented | observed | assumed
source: "guide: Chords"        # where the expectation comes from
cases: [...]                   # kind-specific
```

Shared fields at block level (e.g. `key`) apply to every case unless the
case overrides them.

### Kinds

| Kind | Case fields → expected fields | Runner |
|---|---|---|
| `chord` | `key`, `spec` → `symbol`, `roman`, `tones`, `bass` | motif_theory |
| `note` | `key`, `degree`, `accidental`, `octave` → `name`, `midi`, `scientific` | motif_theory |
| `key-spelling` | `pc`, `scale` → `tonic` | motif_theory |
| `relative-tonic` | `from`, `to` → `tonic` | motif_theory |
| `color` | `scale`, `degree`, `accidental`, `scheme` → `color` | motif_theory |
| `octave` | `previous`, `degree`, `smart`, `shift` → `octave` | motif_theory |
| `edit` | `given`, `keys` → `expect` | pending until `motif_core` lands |

`spec` (chord) fields: `degree` (1–7), `type` (5/7/9/11/13), `inversion`
(0–3), `sus` (2/4), `add` (list of 4/6/9), `omit` (list of 3/5), `alter`
(list of `b5`, `#5`, `b9`, `#9`, `#11`, `b13`), `applied` (`V`/`IV`/`vii`),
`borrow` (scale name).

`color` values: a slot name (`red`, `orange`, `yellow`, `green`, `blue`,
`purple`, `pink`) or a stripe `lower/upper` such as `orange/yellow`.

### Edit-case notation

`edit` cases describe editor state as text so they stay readable:

- A **voice** is a list of note tokens `[accidental]degree[octave marks]/beats`:
  `1/1` is degree 1 for one beat, `#4/0.5` a raised 4 for half a beat,
  `5,/1` degree 5 an octave down, `3'/2` an octave up. Rests are `r/beats`.
- A **chord track** is a list of `numeral/beats`, e.g. `I/4 V65/2 vi/2`.
- The **cursor** is `|` inside a list; a selection is wrapped in `[` … `]`.
- `keys` is a list of key presses in [keymap.md](keymap.md) notation,
  e.g. `["1", "2", "hold:Up 3", "k", "5"]`.
- `given.settings` can set `smartOctave`, `entryMode` (`table`/`text`),
  `duration` (beats) and so on; defaults are the app defaults.
