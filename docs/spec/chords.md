# Chords

Applies to the chord staff (below the melody). Chords are stored relative to
the key in force: a scale degree plus palette settings (see
`packages/motif_theory`).

## Entry and editing

- **CH-1** (documented) With the cursor in the chord staff, typing `1`–`7`
  inserts the diatonic chord on that degree of the current scale.
  Backspace/Delete remove chords like a text editor.
- **CH-2** (observed, from screenshots) The chord palette also has a rest
  slot on `0` and a suggestion slot (★) on `8`.
- **CH-3** (documented) Selecting: drag in an empty part of the staff, or
  along a chord's top or bottom edge, to make a selection bar. Dragging from
  the middle of a chord moves it left/right. Ctrl/Cmd-click, Shift-click and
  Shift+←/→ also select.
- **CH-4** (documented) Duration keys, edge resizing (outer/inner zones),
  Alt-drag in Text mode, split (`/`) and copy/paste all behave as for notes
  (see [melody.md](melody.md)).
- **CH-5** (documented) `t` ties adjacent selected chords only if they have
  the same root.
- **CH-6** (documented) Palette settings chosen while **no chord is
  selected** apply to the next chord entered. With chords selected, they
  change those chords.

```conformance
id: chords.entry
kind: edit
status: documented
source: "guide: Adding / Deleting Chords"
cases:
  - given: {chords: ["|"], settings: {duration: 4}}
    keys: ["1", "4", "5", "1"]
    expect: {chords: ["I/4", "IV/4", "V/4", "I/4", "|"]}
  - given: {chords: ["|"], settings: {duration: 4}}
    keys: ["click:7th", "5", "1"]
    expect: {chords: ["V7/4", "I7/4", "|"]}
```

## Diatonic chords

- **CH-7** (documented) Chords are built by stacking thirds from the
  current scale, so their quality depends on the scale (major I, minor i,
  diminished vii°…).

```conformance
id: chords.diatonic-major
kind: chord
status: documented
source: "guide: Adding / Deleting Chords; Primary Labels screenshot"
key: C major
cases:
  - {spec: {degree: 1}, symbol: C, roman: I, tones: [C, E, G]}
  - {spec: {degree: 2}, symbol: Dm, roman: ii}
  - {spec: {degree: 3}, symbol: Em, roman: iii}
  - {spec: {degree: 4}, symbol: F, roman: IV}
  - {spec: {degree: 5}, symbol: G, roman: V}
  - {spec: {degree: 6}, symbol: Am, roman: vi}
  - {spec: {degree: 7}, symbol: Bdim, roman: "vii°", tones: [B, D, F]}
```

```conformance
id: chords.diatonic-minor
kind: chord
status: documented
source: "guide: Color Scheme (minor example)"
key: A minor
cases:
  - {spec: {degree: 1}, symbol: Am, roman: i}
  - {spec: {degree: 2}, symbol: Bdim, roman: "ii°"}
  - {spec: {degree: 3}, symbol: C, roman: III}
  - {spec: {degree: 4}, symbol: Dm, roman: iv}
  - {spec: {degree: 5}, symbol: Em, roman: v}
  - {spec: {degree: 6}, symbol: F, roman: VI}
  - {spec: {degree: 7}, symbol: G, roman: VII}
```

```conformance
id: chords.diatonic-harmonic-minor
kind: chord
status: assumed
source: "derived from the scale; Hookpad labels not yet checked"
key: A harmonic minor
cases:
  - {spec: {degree: 3}, symbol: Caug, roman: "III+"}
  - {spec: {degree: 5, type: 7}, symbol: E7, roman: V7}
  - {spec: {degree: 7, type: 7}, symbol: "G#dim7", roman: "vii°7"}
```

## Inversions

- **CH-8** (documented) Root, 1st and 2nd inversion are always available;
  3rd inversion only for chords with a seventh. `i` cycles through the
  available inversions.
- **CH-9** (documented) Inversions are labelled with figured bass after the
  numeral: triads none / 6 / 6-4; seventh chords 7 / 6-5 / 4-3 / 4-2.
- **CH-10** (assumed) Chords with a 9th, 11th or 13th show that number in
  root position, and seventh-chord figures (6-5, 4-3, 4-2) when inverted.

```conformance
id: chords.inversions
kind: chord
status: documented
source: "guide: Chord Inversions"
key: C major
cases:
  - {spec: {degree: 1, inversion: 1}, symbol: C/E, roman: I6, bass: E}
  - {spec: {degree: 1, inversion: 2}, symbol: C/G, roman: I64, bass: G}
  - {spec: {degree: 5, type: 7}, symbol: G7, roman: V7}
  - {spec: {degree: 5, type: 7, inversion: 1}, symbol: G7/B, roman: V65}
  - {spec: {degree: 5, type: 7, inversion: 2}, symbol: G7/D, roman: V43}
  - {spec: {degree: 5, type: 7, inversion: 3}, symbol: G7/F, roman: V42}
```

```conformance
id: chords.inversion-labels-observed
kind: chord
status: observed
source: "review screenshot: progression I I6 IV vi64 ii IV Vsus4 V and V6/vi"
key: C major
cases:
  - {spec: {degree: 1, inversion: 1}, symbol: C/E, roman: I6}
  - {spec: {degree: 6, inversion: 2}, symbol: Am/E, roman: vi64}
  - {spec: {degree: 5, sus: 4}, symbol: Gsus4, roman: Vsus4}
  - {spec: {degree: 6, applied: V, inversion: 1}, symbol: "E/G#", roman: V6/vi}
```

## Embellishments

- **CH-11** (observed, from screenshots) Palette groups: **Type** 5 / 7 / 9 /
  11 / 13; **Sus** sus2, sus4; **Add/Omit** add4, add6, add9, no3, no5;
  **Alter** ♭5, ♯5, ♭9, ♯9, ♯11, ♭13 (only offered where they make sense).
- **CH-12** (documented) `e` cycles through embellishment combinations.
  (assumed) The cycle order is: plain, 7, sus4, 7sus4, add9, sus2.
- **CH-13** (assumed) Type extensions stack scale tones (so iii9 in major
  contains a ♭9). sus2/sus4 use a major 2nd / perfect 4th above the root.
  add4/add6/add9 add the scale tone. Alterations set an absolute interval
  above the root and replace the natural tone they alter.
- **CH-14** (assumed) Roman numerals don't mark seventh quality beyond °, ø
  and +, as in classical analysis (IV7, not IVmaj7).

```conformance
id: chords.embellishments
kind: chord
status: assumed
source: "palette from screenshots; voicing rules are our assumption"
key: C major
cases:
  - {spec: {degree: 1, type: 9}, symbol: Cmaj9, roman: I9}
  - {spec: {degree: 3, type: 9}, symbol: "Em7(b9)", roman: iii9}
  - {spec: {degree: 5, type: 13}, symbol: G13, roman: V13}
  - {spec: {degree: 1, sus: 4}, symbol: Csus4, roman: Isus4, tones: [C, F, G]}
  - {spec: {degree: 4, sus: 4}, symbol: Fsus4, roman: IVsus4, tones: [F, Bb, C]}
  - {spec: {degree: 5, type: 7, sus: 4}, symbol: G7sus4, roman: V7sus4}
  - {spec: {degree: 1, add: [9]}, symbol: Cadd9, roman: Iadd9}
  - {spec: {degree: 2, add: [6]}, symbol: Dm6, roman: iiadd6}
  - {spec: {degree: 1, add: [6, 9]}, symbol: "C6/9"}
  - {spec: {degree: 1, omit: [3]}, symbol: C5, roman: Ino3}
  - {spec: {degree: 5, type: 7, alter: [b9]}, symbol: "G7(b9)", roman: "V7(♭9)"}
  - {spec: {degree: 5, type: 7, alter: ["#5"]}, symbol: Gaug7}
  - {spec: {degree: 4, type: 11}, symbol: "Fmaj9(#11)", roman: IV11}
```

## Applied (secondary) chords

- **CH-15** (documented) Applied chords briefly tonicise another chord.
  The functions are V of, IV of and vii° of (`d` cycles them). You pick the
  function first, then type the *target* degree: "V of" then `2` gives V/ii.
- **CH-16** (assumed) V/x and IV/x are built from the major scale on x's
  root, and vii°/x from its harmonic minor, so vii°7/x is fully diminished.
  The target is labelled as the diatonic triad on that degree.

```conformance
id: chords.applied
kind: chord
status: documented
source: "guide: Non-Diatonic Chords (Secondary Chords)"
key: C major
cases:
  - {spec: {degree: 2, applied: V}, symbol: A, roman: V/ii}
  - {spec: {degree: 2, type: 7, applied: V}, symbol: A7, roman: V7/ii}
  - {spec: {degree: 5, applied: V}, symbol: D, roman: V/V}
  - {spec: {degree: 4, type: 7, applied: V}, symbol: C7, roman: V7/IV}
  - {spec: {degree: 5, applied: IV}, symbol: C, roman: IV/V}
```

```conformance
id: chords.applied-sevenths
kind: chord
status: assumed
source: "construction rule CH-16"
cases:
  - {key: C major, spec: {degree: 5, type: 7, applied: vii}, symbol: "F#dim7", roman: "vii°7/V"}
  - {key: A minor, spec: {degree: 4, type: 7, applied: V}, symbol: A7, roman: V7/iv}
  - {key: A minor, spec: {degree: 3, applied: V}, symbol: G, roman: V/III}
```

## Borrowed chords

- **CH-17** (documented) A borrowed chord takes its root and quality from a
  parallel scale (same tonic), chosen in a dropdown. Choosing a mode with no
  chord selected applies it to the next chord entered.
- **CH-18** (assumed) The numeral gets ♭/♯ when the borrowed root differs
  from the key's own degree (♭VI, ♭VII); the UI also shows which scale it
  came from.

```conformance
id: chords.borrowed
kind: chord
status: documented
source: "guide: Non-Diatonic Chords (Borrowed Chords)"
key: C major
cases:
  - {spec: {degree: 2, borrow: minor}, symbol: Ddim, roman: "ii°"}
  - {spec: {degree: 4, borrow: minor}, symbol: Fm, roman: iv}
```

```conformance
id: chords.borrowed-accidentals
kind: chord
status: assumed
source: "labelling rule CH-18"
key: C major
cases:
  - {spec: {degree: 6, borrow: minor}, symbol: Ab, roman: "♭VI"}
  - {spec: {degree: 7, borrow: minor}, symbol: Bb, roman: "♭VII"}
  - {spec: {degree: 3, borrow: minor}, symbol: Eb, roman: "♭III"}
  - {spec: {degree: 2, borrow: phrygian}, symbol: Db, roman: "♭II"}
```

## Labels

- **CH-19** (documented) By default the Roman numeral is the main label and
  the absolute chord name is a smaller label underneath. A setting swaps
  them.
- **CH-20** (documented) Chords are coloured by their position in the scale
  (see [display.md](display.md)).

## Suggestions (M5)

- **CH-21** (documented) Suggest Chord (our name) offers chords for the
  cursor position, ranked by how often they follow the preceding chords in a
  song corpus. A Bass variant suggests chords over a given bass note.
- **CH-22** (documented) Other helpers: popular chords in the key, chord
  search by name, tone sets (chords containing chosen notes), bass sets
  (alternatives with the same bass), and inserting common progressions.

## Open questions

- The exact `e` cycle order, and whether `i`/`e` wrap around.
- Whether `d` cycles none → V → IV → vii → none.
- Which alterations are disabled for which chord types.
- Whether Hookpad's sus4 on IV uses B♭ (perfect 4th) or B (scale tone).
- How ninth/eleventh/thirteenth chords are labelled when inverted.
- How a chord that is both applied and borrowed is labelled.
