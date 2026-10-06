# Display

Colour *values* are ours (theme tokens); the rules below only fix which of
the seven hue slots — red, orange, yellow, green, blue, purple, pink — a note
or chord uses.

## Colour schemes

- **DI-1** (documented) Notes and chords are coloured by scale position.
  Default **diatonic-centric**: in the major scale degrees 1–7 (and chords
  I–vii°) are red, orange, yellow, green, blue, purple, pink.
- **DI-2** (documented) In other scales the colour order is kept but rotated,
  so the colour gap between degrees always matches the interval pattern and
  chord colours keep their quality (the basic red chord is major, the yellow
  one minor, in every scale). Relative keys share colours: A minor's i is the
  same purple as C major's vi.
- **DI-3** (assumed) Harmonic Minor and Phrygian Dominant rotate like their
  parent modes (Aeolian, Phrygian).
- **DI-4** (documented) The alternative **major-centric** scheme colours
  each pitch by its place in the major scale on the same tonic. A pitch
  between two major-scale degrees (e.g. minor 3rd) is striped with both
  neighbours' colours (orange and yellow).
- **DI-5** (observed, from screenshots) Notes with an accidental are striped.
  (assumed) The stripe pairs the degree's colour with the neighbour in the
  direction of the accidental.
- **DI-6** (assumed) A chord takes its colour from its root, so borrowed
  chords with a non-diatonic root are striped and applied chords take the
  colour of their actual root.

```conformance
id: display.diatonic-centric
kind: color
status: documented
source: "guide: Color Scheme"
scheme: diatonic
cases:
  - {scale: major, degree: 1, color: red}
  - {scale: major, degree: 2, color: orange}
  - {scale: major, degree: 3, color: yellow}
  - {scale: major, degree: 4, color: green}
  - {scale: major, degree: 5, color: blue}
  - {scale: major, degree: 6, color: purple}
  - {scale: major, degree: 7, color: pink}
  - {scale: minor, degree: 1, color: purple}
  - {scale: minor, degree: 2, color: pink}
  - {scale: minor, degree: 3, color: red}
```

```conformance
id: display.major-centric
kind: color
status: documented
source: "guide: Color Scheme (minor example)"
scheme: major
cases:
  - {scale: minor, degree: 1, color: red}
  - {scale: minor, degree: 2, color: orange}
  - {scale: minor, degree: 3, color: orange/yellow}
  - {scale: minor, degree: 4, color: green}
  - {scale: minor, degree: 5, color: blue}
  - {scale: minor, degree: 6, color: blue/purple}
  - {scale: minor, degree: 7, color: purple/pink}
```

```conformance
id: display.accidental-stripes
kind: color
status: assumed
source: "rule DI-5"
scheme: diatonic
cases:
  - {scale: major, degree: 4, accidental: 1, color: green/blue}
  - {scale: major, degree: 7, accidental: -1, color: purple/pink}
  - {scale: major, degree: 1, accidental: -1, color: pink/red}
```

## Labels

- **DI-7** (documented) Primary label setting: Roman numerals (default) or
  absolute chord names; the other is shown smaller under the chord.
- **DI-8** (observed, from screenshots) The note-row labels show the degree
  and the absolute letter (`5 G`), with the tonic row highlighted.

## Staff spacing

- **DI-9** (documented) **Compact** (default): the melody staff has one row
  per scale degree.
- **DI-10** (documented) **Expanded (chromatic)**: one row per semitone, so
  rows are spaced by the real intervals and chromatic notes have their own
  row.

## Chord compatibility guides

- **DI-11** (documented) When on, each melody row is tinted under a chord
  only if that degree is a tone of the chord; other rows are white, showing
  at a glance which melody notes are stable over each chord.

## Inactive voices

See MEL-24 in [melody.md](melody.md).

## Open questions

- How stripes look for double accidentals and for chromatic chord roots in
  the major-centric scheme.
- Whether compatibility guides consider sevenths/extensions or only the
  triad.
