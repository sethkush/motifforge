# Song structure

## Measures

- **ST-1** (documented) Measures are added automatically when entry reaches
  the end of the song.
- **ST-2** (documented) Clicking the measure bar above the melody staff
  selects a measure; dragging selects several. With measures selected, the
  measure panel can add N measures before or after them, delete them, add a
  key/meter/tempo/band change, add a line break, or export just that range.
- **ST-3** (observed, from screenshots) A handle at the end of the last
  measure can be dragged to add or remove measures, and +/− buttons do the
  same.

## Key and scale

- **ST-4** (documented) New songs are in C Major.
- **ST-5** (documented) The key picker has the 12 tonics on a circle of
  fifths and these scales, in order: Major, Minor, Dorian, Phrygian, Lydian,
  Mixolydian, Locrian, Harmonic Minor, Phrygian Dominant.
- **ST-6** (observed, from screenshots) The circle uses the names C, G, D,
  A, E, B, F♯, D♭, A♭, E♭, B♭, F. (assumed) Other scales on the same tonic
  use whichever spelling needs fewer accidentals, falling back to the circle
  name on a tie.

```conformance
id: structure.key-spelling
kind: key-spelling
status: observed
source: "key picker screenshot (circle of fifths)"
scale: major
cases:
  - {pc: 1, tonic: Db}
  - {pc: 3, tonic: Eb}
  - {pc: 6, tonic: "F#"}
  - {pc: 8, tonic: Ab}
  - {pc: 10, tonic: Bb}
```

```conformance
id: structure.key-spelling-minor
kind: key-spelling
status: assumed
source: "rule ST-6 (fewest accidentals)"
scale: minor
cases:
  - {pc: 1, tonic: "C#"}
  - {pc: 3, tonic: Eb}
  - {pc: 8, tonic: "G#"}
  - {pc: 10, tonic: Bb}
```

- **ST-7** (documented) Changing the scale has two modes:
  - **Parallel** (default) keeps the tonic and every note's scale degree and
    chord number; pitches follow the new scale (I in C Major → i in C Minor).
  - **Relative** keeps every pitch; the tonic moves to the related scale and
    degrees/numbers are renumbered (C Major → A Minor, I → III). The tonic
    choice is disabled in this mode because it is determined.
- **ST-8** (assumed) Harmonic Minor and Phrygian Dominant move as their
  parent modes (Aeolian and Phrygian) in a relative change. Pitches that
  don't fit the new scale keep their pitch and get an accidental.

```conformance
id: structure.relative-tonic
kind: relative-tonic
status: documented
source: "guide: Scale Transposition"
cases:
  - {from: C major, to: minor, tonic: A}
  - {from: A minor, to: major, tonic: C}
```

```conformance
id: structure.relative-tonic-modes
kind: relative-tonic
status: assumed
source: "rule ST-8 and mode rotation"
cases:
  - {from: C major, to: dorian, tonic: D}
  - {from: E phrygian, to: lydian, tonic: F}
  - {from: Eb major, to: minor, tonic: C}
  - {from: A harmonic minor, to: major, tonic: C}
  - {from: C major, to: locrian, tonic: B}
```

```conformance
id: structure.scale-change
kind: edit
status: documented
source: "guide: Scale Transposition"
cases:
  - given: {key: C major, chords: ["I/4"]}
    keys: ["dialog:key scale=minor change=parallel"]
    expect: {key: C minor, chords: ["i/4"]}
  - given: {key: C major, chords: ["I/4"]}
    keys: ["dialog:key scale=minor change=relative"]
    expect: {key: A minor, chords: ["III/4"]}
```

- **ST-9** (documented) Key changes can be added at a selected measure. They
  appear as flags; selecting a flag edits that key, Delete removes it.

## Meter

- **ST-10** (documented) Beats per measure can be 2, 3, 4, 5, 6, 9 or 12.
  Choosing a meter for a new song starts a new project with that many beats.
- **ST-11** (documented) For 3, 6, 9 and 12 beats there is a **beat unit**
  option. With beat unit 3, three beats are felt as one (compound time), and
  the tempo counts those grouped beats, so playback is three times faster at
  the same tempo number.
- **ST-12** (documented) Meter changes go on a selected measure. The new
  meter lasts for a chosen range of measures, until the next meter change,
  or to the end of the song. Changes appear as selectable, deletable flags.
- **ST-13** (documented) The entry durations available depend on the meter
  (see MEL-12).

## Tempo

- **ST-14** (documented) Tempo is set with a slider, or by tap tempo: press
  Tap, then tap `q` in time and the tempo is computed from the taps.
- **ST-15** (documented) A "swing time" checkbox gives the song a swing
  feel.
- **ST-16** (documented) Tempo changes are added at measures, like key and
  meter changes.

## Band changes

- **ST-17** (documented) The band (instrumentation) can change at a selected
  measure; Band Change flags appear and open that band for editing.

## Sections

- **ST-18** (observed, from screenshots) Named sections (e.g. "Verse 1")
  label a range of measures above the measure bar. Lyrics are organised by
  section.

## Looping

- **ST-19** (documented) The loop bar above the melody staff sets a loop
  range. Clicking it turns looping on and off; playback repeats the range.

## Line breaks

- **ST-20** (documented) By default each line shows 8 measures.
- **ST-21** (documented) Enter forces a line break at the cursor's measure;
  so does "add line break" in the measure panel. Selecting the break marker
  at the end of a line and pressing Delete (or "delete break") removes it.
- **ST-22** (documented) Settings: N measures per line, fit to window, one
  long line, or manual breaks only.

## Open questions

- Exact wording/order of the measure-panel actions.
- What happens to notes past the end of the song when measures are deleted.
- Whether tempo changes ramp or jump.
- Swing ratio and which note value swings (8ths in 4/4?).
