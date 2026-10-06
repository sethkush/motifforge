# Melody

Applies to the melody staff (the coloured scale-degree rows above the chord
staff). "Beat" means the meter beat. Defaults: one voice active, Table entry
mode, Smart Octave on, entry duration 1 beat.

## Entry

- **MEL-1** (documented) With the cursor in the melody staff, typing `1`–`7`
  inserts that scale degree at the cursor with the current entry duration,
  and the cursor moves to the note's end. `0` inserts a rest.
- **MEL-2** (documented) Backspace deletes the note before the cursor,
  Delete the note after it, as in a text editor. With a selection, either
  key deletes the selection.
- **MEL-3** (documented) The song gets longer by itself when entry reaches
  the end of the last measure.

```conformance
id: melody.entry
kind: edit
status: documented
source: "guide: Adding / Deleting Notes"
cases:
  - given: {voice: ["|"]}
    keys: ["1", "2", "3"]
    expect: {voice: ["1/1", "2/1", "3/1", "|"]}
  - given: {voice: ["|"]}
    keys: ["1", "0", "5"]
    expect: {voice: ["1/1", "r/1", "5,/1", "|"]}
  - given: {voice: ["1/1", "2/1", "|", "3/1"]}
    keys: ["Backspace"]
    expect: {voice: ["1/1", "|", "3/1"]}
```

## Octave placement

- **MEL-4** (documented) With **Smart Octave** on, a new note goes in the
  octave that puts it closest to the previous note. Distance is counted in
  scale steps, so there's never a tie: up to 3 steps away it stays close,
  4 steps away it jumps to the other side.
- **MEL-5** (documented) With Smart Octave off, the new note uses the
  previous note's octave.
- **MEL-6** (documented) Holding ↑ or ↓ while typing a digit enters the note
  one octave above or below where it would otherwise go.
- **MEL-7** (documented) Five octaves are available. (assumed) Placement is
  clamped to them.
- **MEL-8** (assumed) The first note of a voice, with nothing before it,
  goes in the default octave (octave 0: tonic at or above middle C).

```conformance
id: melody.smart-octave
kind: octave
status: documented
source: "guide: Note Octave, Smart Octave"
cases:
  - {degree: 5, octave: 0}
  - {previous: {degree: 1}, degree: 4, octave: 0}
  - {previous: {degree: 1}, degree: 5, octave: -1}
  - {previous: {degree: 1}, degree: 7, octave: -1}
  - {previous: {degree: 7}, degree: 1, octave: 1}
  - {previous: {degree: 6, octave: -1}, degree: 2, octave: 0}
  - {previous: {degree: 1}, degree: 7, smart: false, octave: 0}
  - {previous: {degree: 1}, degree: 2, shift: 1, octave: 1}
  - {previous: {degree: 1}, degree: 5, shift: -1, octave: -2}
  - {previous: {degree: 1, octave: 2}, degree: 1, shift: 1, octave: 2}
```

## Selection

- **MEL-9** (documented) Notes can be selected by dragging a box, by
  Ctrl/Cmd-click (toggle one note), by Shift-click (extend), and with
  Shift+←/→ (extend by one note from the cursor).

## Changing pitch

- **MEL-10** (documented) Dragging a note vertically changes its pitch.
- **MEL-11** (documented) With notes selected, ↑/↓ moves them one scale step,
  passing into the next octave at the ends. Shift+↑/↓ moves them a whole
  octave. The note panel has matching Raise/Lower, Raise/Lower Octave and
  Raise/Lower Half buttons.

```conformance
id: melody.pitch-keys
kind: edit
status: documented
source: "guide: Note Pitch, Note Octave"
cases:
  - given: {voice: ["[7/1]"]}
    keys: ["Up"]
    expect: {voice: ["[1'/1]"]}
  - given: {voice: ["[3/1]"]}
    keys: ["Shift+Down"]
    expect: {voice: ["[3,/1]"]}
```

## Durations

- **MEL-12** (documented) The entry-duration keys are `h j k l ; ' b`. The
  first four are ¼, ½, 1 and 2 beats. `'` and `b` are longer values (exact
  lengths unknown, see open questions). Only durations that fit in the
  current meter's measure are offered; in a 12-beat meter all seven are
  available, in 4 beats only `h`–`;`. (observed) The fifth value (`;`) read 4
  in a 4-beat meter and 3 in a 3-beat meter. (assumed) It is the largest
  value that fits the measure.
- **MEL-12a** (observed) Under the ladder is **ADD (⇧)**. (assumed) Holding
  Shift while choosing a duration adds it to the current entry duration
  instead of replacing it (a tablet capture showed "Duration: 2.25", i.e.
  2 + ¼).
- **MEL-13** (documented) Duration buttons can also be clicked.
- **MEL-14** (documented) Dragging a note's edge resizes it. Each edge has
  two zones:
  - **outer edge**: the touching neighbour moves its shared edge too, so it
    shrinks or grows to stay attached;
  - **inner edge**: the neighbour is not attached and gets overwritten as the
    note grows.
- **MEL-15** (documented) In Text entry mode only, holding Alt/Option while
  dragging pushes or pulls every later note along with the edge.

```conformance
id: melody.duration-keys
kind: edit
status: documented
source: "guide: Note Duration"
cases:
  - given: {voice: ["|"]}
    keys: ["j", "1", "1", "l", "5"]
    expect: {voice: ["1/0.5", "1/0.5", "5/2", "|"]}
  - given: {voice: ["|"]}
    keys: ["h", "3"]
    expect: {voice: ["3/0.25", "|"]}
```

## Split and tie

- **MEL-16** (documented) `/` (or the Split button) toggles split mode; while
  it's on, clicking a note cuts it in two at the click position.
- **MEL-17** (documented) `t` (or Tie) joins selected adjacent notes. It only
  works when they have the same pitch.

```conformance
id: melody.tie
kind: edit
status: documented
source: "guide: Tying (Joining) Notes"
cases:
  - given: {voice: ["[4/1", "4/1]"]}
    keys: ["t"]
    expect: {voice: ["[4/2]"]}
  - given: {voice: ["[4/1", "5/1]"]}
    keys: ["t"]
    expect: {voice: ["[4/1", "5/1]"]}
```

## Non-diatonic notes

- **MEL-18** (documented) `.` raises the selected notes a half step and `,`
  lowers them (raised 4 is shown as ♯4).
- **MEL-19** (documented) Holding `.` or `,` while typing a digit enters the
  note already raised or lowered.
- **MEL-20** (documented) Accidentals are spelled from the degree's letter:
  ♯2 in C is D♯, never E♭.

```conformance
id: melody.accidentals
kind: edit
status: documented
source: "guide: Non-Diatonic Notes"
cases:
  - given: {voice: ["[4/1]"]}
    keys: ["."]
    expect: {voice: ["[#4/1]"]}
  - given: {voice: ["|"]}
    keys: ["hold:, 7"]
    expect: {voice: ["b7/1", "|"]}
```

```conformance
id: melody.note-spelling
kind: note
status: documented
source: "guide: Non-Diatonic Notes; Exporting as a Score (enharmonics)"
cases:
  - {key: C major, degree: 2, accidental: 1, name: "D#"}
  - {key: C major, degree: 3, accidental: -1, name: "Eb"}
  - {key: C major, degree: 4, accidental: 1, name: "F#"}
  - {key: F# major, degree: 7, name: "E#"}
  - {key: Db major, degree: 4, name: "Gb"}
  - {key: A minor, degree: 7, accidental: 1, name: "G#"}
  - {key: C major, degree: 1, midi: 60, scientific: "C4"}
  - {key: C major, degree: 5, octave: -1, midi: 55, scientific: "G3"}
  - {key: B major, degree: 3, midi: 75, scientific: "D#5"}
```

## Voices

- **MEL-21** (documented) There are four melody voices. Ctrl+1 … Ctrl+4 makes
  a voice active; new notes go into the active voice.
- **MEL-22** (documented) Each voice has its own lyrics, and its own
  instrument, octave and volume in the band.
- **MEL-23** (documented) Each voice can be shown or hidden and played or
  muted independently.
- **MEL-24** (documented) Inactive voices are drawn in one of three styles:
  translucent (default), solid, or outlined with a per-voice colour (voice 1
  red, 2 orange, 3 yellow, 4 green). Backtick cycles the style. (observed)
  One capture showed Outlined selected, probably a user choice; the guide
  names Translucent as the default.

## Triplets

- **MEL-25** (documented) "Make Triplet" on a selected quarter note (1 beat)
  makes three eighth-note triplets. On a half note (2 beats) it makes three
  quarter-note triplets. Sixteenth-note triplets aren't supported.

```conformance
id: melody.triplets
kind: edit
status: documented
source: "guide: Triplets"
cases:
  - given: {voice: ["[1/1]"]}
    keys: ["click:Make Triplet"]
    expect: {voice: ["[1/0.333", "1/0.333", "1/0.333]"]}
```

## Open questions

- Whether ADD accumulates only with Shift held, or toggles a mode (the
  tablet has no Shift key).

- Exact lengths for the `'` and `b` duration keys, and which meters offer them.
- Whether Backspace with no selection deletes the note or shortens the gap in
  Table mode.
- Where the cursor lands after Make Triplet.
- What `,`/`.` do to a note that already has an accidental (double sharp, or
  limit to ±1).
