# Screen layout

Where things are on screen, from screenshots in the public user guide and a
published review. This only covers placement and grouping. Visual styling
(icons, colour values, fonts) is our own; see `docs/PLAN.md` §0.

The screenshots show two generations of the desktop UI (a "classic" one with
text menus and a newer header with icon buttons) plus a tablet layout. We
target the newest one but keep anything the newer screenshots don't
contradict.

## Desktop window, top to bottom

1. **Menu / title bar** (observed). App menu, File, Edit, Help,
   Preferences, MIDI Preferences in one capture; File, Edit, MIDI, Settings,
   Help in another. The song title sits at the right, with an "Edited"
   marker when there are unsaved changes, then the account avatar.
2. **Toolbar** (observed), left to right:
   - Transport: Play, Record, Loop, Click (metronome), Volume, Preview.
   - Song settings: Meter (shows beats per measure), Key (tonic + short
     scale name, e.g. "C Maj"), Tempo, Band, Lyrics, Sections.
   - Newer header only: an AI-assistant button in the centre; Guides,
     YouTube, Audio Track and Metrics on the right.
   - Zoom (−, %, +) and horizontal zoom (−, %, +), then Delete.
3. **Palette strip** (observed). Its content follows the staff the cursor
   is in:
   - *Melody*: duration ladder; "Notes in ⟨key⟩" swatches; pitch buttons;
     voice panel (details below).
   - *Chords*: "Chords in ⟨key⟩" swatches; embellishment groups (below).
4. **Score** (observed): a vertical list of systems (lines), each 8
   measures wide by default.

### Duration ladder (observed)

A "Duration: N" readout above one bar per value, labelled with its beat
length and its key: ¼ (h), ½ (j), 1 (k), 2 (l), then the fifth value
(;). The fifth value showed 3 in a 3-beat meter and 4 in a 4-beat meter
(see MEL-12). Under the ladder: **ADD (⇧)**, then **Split** and **Tie**
buttons.

### Melody palette (observed)

- Seven degree swatches in degree colours, each showing the degree number,
  the absolute letter and the key hint (`C (1)` … `B (7)`), plus a rest
  swatch.
- Pitch buttons: Raise Half (.), Lower Half (,), Raise (↑), Lower (↓),
  Raise Octave (⇧↑), Lower Octave (⇧↓). The newer UI adds Make Triplet.
- Voice management: for voices 1–4, an Active radio, a Show checkbox
  (empty voices marked "(Empty)"), a Play checkbox, and Inactive Coloring
  radios: Outlined / Solid / Translucent.

### Chord palette (observed)

- Seven chord swatches for the current scale (I ii iii IV V vi vii° in
  major), each with the absolute name and key hint (1)–(7), then a rest
  slot (0) and a suggestion slot (★, 8). Newer captures show one or two
  more suggestion-style slots after ★.
- Groups, left to right: Type (e) 5/7/9/11/13; Inversion (i)
  None/1st/2nd/3rd; Sus sus2/sus4; Add/Omit add4/add6/add9/no3/no5; Alter
  ♭5/♯5/♭9/♯9/♯11/♭13; Secondary (d) None / V of / IV of / vii of; Borrow
  (dropdown, "N/A" when off).

### A system (observed), top to bottom

1. Flags for section names, band changes ("Band 1", "Band 2"), key,
   meter and tempo changes, at the measure where they start.
2. Measure-number bar (clickable to select measures).
3. Loop bar (↻ marks the loop start).
4. Melody staff: one row per degree, labelled "degree letter" (`5 G`),
   tonic row label in red. Rows extend into the octave below or above
   when notes are there (labels repeat: … 2 D, 1 C, 7 B, 6 A …).
5. Lyrics (when on), placed above or on their notes.
6. Chord staff: one box per chord, the numeral large (figured bass as
   stacked superscripts, sus as a subscript, applied as `V⁶/vi`), a bar in
   the chord's colour along the top and bottom edges, and the absolute name
   under the box (`C/E`, `Gsus4`).

At the end of the last system there's a square handle for adding or
removing measures.

## Tablet layout (observed, one capture)

- Toolbar: Play, Delete, Undo, Redo, Cut, Copy, Paste, Nudge, Zoom.
- Duration ladder as on desktop; tapping several durations with ADD
  accumulates them (the readout showed 2.25).
- Note palette as tall vertical buttons for degrees 1–7 plus rest, with a
  **Chromatic** toggle.
- **Chord-tone dots**: dots under the note-palette buttons that belong to
  the chord at the cursor (C, E and A under an A-minor chord).
- Dragging a note shows a **magnifier loupe** around the finger.

## Installation (observed)

The web app can be installed from the browser ("Install app" prompt), so
it ships as an installable web app (PWA).

## Open questions

- Grey note blocks appear on the staff in several captures. Are they rests,
  notes muted by a setting, or another voice?
- What the Preview toolbar toggle does. (assumed) It plays notes and
  chords as you enter or select them.
- Which slots follow ★ in the newer chord palette, and their keys.
- Exact grouping of the newest header (Aria/Guides/Metrics panels).
