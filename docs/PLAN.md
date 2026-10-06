# MotifForge — Project Plan

MotifForge is an open-source, cross-platform (Flutter/Dart) songwriting tool in
the spirit of Hooktheory's Hookpad: you write melodies and chords as **scale
degrees and Roman numerals** rather than absolute pitches, hear them played
back by an auto-arranged band, and export to MIDI, notation and audio.

This plan is built from the Hookpad User Guide (v2.1.0). Section 1 is an
inventory of everything that guide describes, written in our own words. The
rest of the plan covers how we build it.

> **Clean-room rule.** We copy *behaviour*, not *assets or text*. Don't put
> Hooktheory's name, logo, UI artwork, sound samples, guide text or TheoryTab
> data into this repo. Everything in `docs/` is paraphrased. Musical ideas such
> as scale degrees, Roman numerals and colour-coding by degree are common
> knowledge and free to use.

---

## 1. Feature inventory (what Hookpad does)

### 1.1 Melody
| Feature | Behaviour |
|---|---|
| Note entry | Click in the melody staff, then type `1`–`7` to add scale degrees (`0` = rest). Backspace/Delete removes notes like a text editor does. |
| Octave placement | **Smart Octave** (default) places a new note in the octave closest to the previous note. When it's off, the note goes in the same octave as its neighbour. Holding ↑/↓ while typing a digit forces the octave above/below. 5 octaves are supported. |
| Selection | Rubber-band box, Ctrl/Cmd-click, Shift-click, Shift+←/→. |
| Pitch edit | Drag vertically, or ↑/↓ to step through the scale. Shift+↑/↓ moves a whole octave. There are also Raise/Lower buttons. |
| Duration | Drag a note edge. From the *outer* edge the neighbour resizes with it. From the *inner* edge the note eats into its neighbour. In Text mode, Alt-drag pushes or pulls every following note. Keys `h j k l ; ' b` choose the entry duration (¼, ½, 1, 2, 4 beats, plus longer values); which ones are available depends on the meter. |
| Split / tie | `/` toggles split mode (click to cut a note). `t` ties selected adjacent notes that have the same pitch. |
| Accidentals | `.` raises and `,` lowers by a half step. Holding either key while typing a digit enters the note already altered. |
| Voices | 4 melody voices; Ctrl+1…4 switches between them. Each voice has its own lyrics, instrument, octave and volume. Inactive voices can be drawn translucent, solid or outlined (colour per voice); backtick cycles the style. There are per-voice visible and play toggles. |
| Triplets | "Make Triplet" splits a quarter into 3 eighth-triplets, or a half into 3 quarter-triplets. There are no 16th triplets. |

### 1.2 Chords
| Feature | Behaviour |
|---|---|
| Entry | Type `1`–`7` in the chord staff to add diatonic chords; Backspace deletes. |
| Selection / move | Drag in an empty area or along a chord's top/bottom edge to select a range. Dragging from a chord's middle moves it. Ctrl/Shift-click and Shift+arrows also select. |
| Duration / split / tie | Same as notes. Tie needs adjacent chords with the same root. |
| Inversion | Root, 1st, 2nd, and 3rd (7th chords only). `i` cycles through them. Shown as figured bass: none, ⁶, ⁶₄, ⁷, ⁶₅, ⁴₃, ⁴₂. |
| Type | Triad (5), 7, 9, 11, 13. `e` cycles through embellishment combinations. |
| Sus | sus2, sus4 |
| Add / omit | add4, add6, add9, no3, no5 |
| Alterations | ♭5, ♯5, ♭9, ♯9, ♯11, ♭13 (enabled only where they make sense) |
| Applied (secondary) | V of, IV of, vii° of. You pick the function, then type the target chord. For example, "V of" + `2` gives V/ii. |
| Borrowed | Pick a parallel mode from a dropdown and the chord is built from that mode's scale on the same tonic. |
| Sticky palette | When nothing is selected, palette settings apply to the *next* chord you enter. |
| Labels | Roman numeral is the primary label and the absolute chord name is secondary. A setting swaps them. |
| Magic Chord | Suggests the next chord at the cursor, ranked by how often it follows the preceding chords in a song corpus. |
| Other smart tools | Popular chords in the current key; chord search by name; **Tone sets** (chords containing chosen notes); **Bass sets** (alternative chords over the same bass note); **Progressions** (insert common progressions). |

### 1.3 Song structure
| Feature | Behaviour |
|---|---|
| Measures | The song grows automatically as you write. You can add N measures before or after a selection, select measures from the bar above the staff, and delete several at once. |
| Key / scale | The default is C major. Tonic is picked on a circle of fifths. Scales: Major, Minor, Dorian, Phrygian, Lydian, Mixolydian, Locrian, Harmonic Minor, Phrygian Dominant. |
| Scale change type | **Parallel** (default) keeps degrees and changes pitches: I in C major becomes i in C minor. **Relative** keeps pitches and changes degrees: C major → A minor, so I becomes III. |
| Key changes | Placed at a measure and shown as flags. |
| Meter | 2, 3, 4, 5, 6, 9 or 12 beats per measure. Compound meters (3/6/9/12) have a "beat unit = 3" option where 3 beats are felt as one, and tempo follows it. Meter changes apply to a measure range, until the next change, or to the end of the song. They show as flags you can select and delete. |
| Tempo | Slider, tap tempo (`q`), swing checkbox, tempo changes. |
| Band changes | Instrumentation can change at a measure. |
| Sections | Named sections such as "Verse 1". Lyrics are organised by section. |
| Line breaks | 8 measures per line by default. Enter forces a break. Settings: N per line, auto-fit to window, one long line, or manual breaks only. |
| Looping | A loop bar above the staff; click it to enable or disable. |

### 1.4 Band, playback and sound
* **Tracks** have a *type* (lead1–4, harmony, bass, drums), a *sound*, a *volume* and an *octave*. Lead octave is ±1 in steps. For harmony and bass it is a continuous voicing centre, measured in octaves.
* You can add, remove and mute tracks. The sound list is filtered by track type and grouped into categories (Piano, Orchestral, Vocals, Synth, Plugged Synth, Percussive…).
* **Band templates** come built in, and users can save their own. Applying one replaces the current band.
* There are **7 playback channels**: 4 leads, harmony, bass and drums. Each can be muted.
* **Harmony styles** set the rhythm and voicing. The default is a right-hand piano chord on every beat. Some styles are meter-aware (e.g. a bossa piano). Voicings use 3 notes: chords with more than 3 notes drop the bass, so you need a bass track to hear the inversion. The voicing is centred on the octave slider (+⅓ octave turns C-E-G into E-G-C).
* **Guitar voicing**: open position when there's a common shape, otherwise an E- or A-shape barre at the lowest fret. Distorted sounds play 2-string power chords; for inversions they voice the first interval (G/B → B-G).
* **Bass styles**: the default is a dotted rhythm on the chord's bass note. Others (e.g. bossa bass) walk through chord tones and adapt to the meter.
* **Drums** come in four kinds:
  * *Basic*: the same bar repeated (one variant alternates two bars).
  * *Regular*: a start bar, a groove, and fill 1 and fill 2. A fill closes every 8th bar, alternating between the two, and one closes the region.
  * *Breaks*: a single ending hit that closes the previous region.
  * *Pickups*: a lead-in fill into whichever groove the next region uses.

  Drums play for the whole band region, whether or not chords are present.
* Click track, master volume, and a record button for real-time MIDI input.

### 1.5 Audio tracks
Import WAV or MP3. A dialog asks for the clip's BPM and meter (with tap tempo) and can auto-add measures. You insert the clip at the start, at the cursor, or after the previous clip, then drag to move it. The bottom corner resizes the clip and the top corner loops it. Controls: lane zoom, waveform zoom, sync offset (fine and coarse nudges), volume, mute, solo, loop, split, delete. There's also a "delete unused files" command.

### 1.6 Export
Each export covers the whole song, or just the selected measures.
* **Score PDF**: a melody staff plus a 2-staff piano harmony part. It spells notes for the key (♯2 → D♯ in C, not E♭).
* **Guitar tab PDF** with fingerings for chords and melody.
* **Lead sheet PDF**.
* **MIDI** (SMF format 1), one track per band track, including volume and octave.
* **MP3**.

### 1.7 Settings
* **Entry mode**: *Table* (default) overwrites and allows gaps. *Text* inserts, pushing later notes along, and fills gaps with rests.
* **Primary labels**: Roman numerals or absolute names.
* **Colour scheme**:
  * *Diatonic-centric*: colours rotate with the mode, so relative keys share colours.
  * *Major-centric*: colours follow major-scale pitch; a lowered degree is striped with the two neighbouring colours.
* **Chord compatibility guides**: chord tones are tinted in the melody staff and non-chord tones are white.
* **Smart Octave** on or off.
* **Note staff spacing**: compact (7 rows, in-scale) or expanded (chromatic, 12 rows).

### 1.8 Lyrics
A lyrics panel splits text into syllables automatically and places one per melody note.
* `-` forces a split inside a word. A single trailing dash keeps the word as one syllable.
* `_` skips a note and `_3_` skips three.
* In the editor, Tab inserts a "skip N notes" box; adjust it with `+`/`-`.
* Lyrics are per section and per voice.

### 1.9 Input, sync, editing
* **MIDI controller**: a played pitch is converted to a scale degree in the current key (step entry). In **record mode** you play in time and the notes are quantised.
* **YouTube sync**: attach a URL, then set start and end markers with `[` and `]` while it plays (the span must be a whole number of measures). A "test the sync" mode follows along, `p` plays or pauses the video, and markers can be nudged. Used for transcription.
* **Clipboard**: `c`/`v` (with or without Ctrl/Cmd) copy and paste. "Paste from clipboard" works across projects using a JSON payload like `{"notes":[{"sd":"1","octave":0,"beat":1,"duration":1,"isRest":false}],"chords":[],"fp":"…"}`.
* **Undo/redo**: `z`/`y`, 20 levels.

### 1.10 Shown in the UI but not documented in the guide (stretch / out of scope)
"Aria" (AI assistant, beta), "Guides", "Metrics", TheoryTab publishing, accounts and activation. The first three are stretch goals. We won't build TheoryTab publishing or accounts.

---

## 2. Product goals and non-goals

**Goals**
1. Keyboard-first and fast. The full song-writing loop works without the mouse.
2. Same theory depth as Hookpad: all 9 scales, embellishments, borrowed and applied chords.
3. Runs offline on Web, macOS, Windows, Linux, iPadOS and Android tablets. Phones get a reduced layout later.
4. Open, documented file format, plus MIDI and MusicXML in and out, so users are never locked in.
5. Extensible content: sounds, harmony and bass styles, drum patterns and progressions are data files the community can contribute to.

**Non-goals (for v1)**
Accounts or cloud sync, a social or TheoryTab-style database, YouTube publishing workflows, and a full DAW (mixing, effects, audio recording).

---

## 3. Architecture

### 3.1 Repository layout (Dart pub workspace)

```
motifforge/
├─ pubspec.yaml                 # workspace root (Dart ≥3.6 `workspace:`)
├─ packages/
│  ├─ motif_theory/             # pure Dart, no Flutter
│  ├─ motif_core/               # song model, edits, undo, (de)serialisation
│  ├─ motif_engine/             # song + band  → timed note events
│  ├─ motif_audio/              # synth + audio output + transport (Flutter plugin deps)
│  ├─ motif_io/                 # MIDI / MusicXML / WAV / MP3 / PDF / clipboard
│  └─ motif_suggest/            # Magic Chord model, tone/bass sets, progressions
├─ apps/
│  └─ motifforge/               # Flutter UI
├─ assets/
│  ├─ soundfonts/               # permissively-licensed SF2/SF3
│  ├─ styles/                   # harmony/bass style definitions (YAML/JSON)
│  ├─ drums/                    # drum pattern definitions
│  └─ models/                   # chord n-gram tables
└─ docs/
```

Everything below `motif_audio` is **pure Dart**. Theory, model, engine and IO
can therefore be unit-tested quickly without Flutter, and reused in a CLI or
server later.

### 3.2 Time representation
* A song is a flat timeline in **ticks**, with `ticksPerBeat = 480`. 480 divides by 3 (triplets) and by 16 (quarter-beat entry), and it matches common MIDI PPQ, so MIDI export needs no rescaling.
* "Beat" means the *meter beat*. When the beat unit is 3 (compound meters), a beat maps to an eighth note in notation and MIDI (6 beats → 6/8). Otherwise it maps to a quarter note.
* Measures, keys, meters, tempi and bands are **maps keyed by measure index**. A `Timeline` helper converts between `(measure, beat)` and ticks and seconds. Swing is applied in the engine, not stored in the notes.

### 3.3 Core model (`motif_core`, immutable, `freezed` + `fast_immutable_collections`)

```dart
class Song {
  SongMeta meta;                    // title, artist, schemaVersion
  int measureCount;
  SortedMap<int, KeyChange> keys;   // measure → (tonic pitch class, Scale)
  SortedMap<int, MeterChange> meters; // measure → (beatsPerMeasure, beatUnit 1|3)
  SortedMap<int, TempoChange> tempos; // measure → (bpm, swing)
  SortedMap<int, Band> bands;       // measure → Band
  List<Section> sections;           // name + measure range
  Set<int> lineBreaks;
  LoopRange? loop;
  List<Voice> voices;               // exactly 4
  List<ChordEvent> chords;
  List<AudioClip> audioClips;
  YouTubeSync? youtube;
}

class NoteEvent {                   // relative to the key in force at `start`
  int start, duration;              // ticks
  bool isRest;
  int degree;                       // 1–7
  int accidental;                   // −1, 0, +1 (half-step raise/lower)
  int octave;                       // −2…+2 relative to the voice's base octave
  TupletInfo? tuplet;
}

class ChordEvent {
  int start, duration; bool isRest;
  int degree;                       // 1–7 root in the (possibly borrowed) scale
  ChordType type;                   // triad, seventh, ninth, eleventh, thirteenth
  int inversion;                    // 0–3
  Sus sus;                          // none, sus2, sus4
  Set<AddTone> adds;                // add4, add6, add9
  Set<OmitTone> omits;              // no3, no5
  Set<Alteration> alterations;      // b5 #5 b9 #9 #11 b13
  Applied applied;                  // none, fiveOf, fourOf, sevenOf
  Scale? borrowedFrom;              // parallel mode, same tonic
}
```

Because notes and chords are stored *relative to the key*, the parallel and
relative scale changes (§1.3) are simple model transforms.

**Edits.** Every user action is a pure function `Song → Song`, wrapped in a
`Command` that records a label for the undo menu. Undo/redo is a persistent
stack of `Song` snapshots; structural sharing keeps that cheap. We'll allow
more than Hookpad's 20 levels (default 200). Edits are written against an
`EditContext` that carries the entry mode (Table or Text), Smart Octave and
the current palette settings.

### 3.4 Theory (`motif_theory`)
* `Scale` holds a semitone pattern per mode:
  * Major `0 2 4 5 7 9 11`, Dorian `0 2 3 5 7 9 10`, Phrygian `0 1 3 5 7 8 10`
  * Lydian `0 2 4 6 7 9 11`, Mixolydian `0 2 4 5 7 9 10`, Minor `0 2 3 5 7 8 10`
  * Locrian `0 1 3 5 6 8 10`, Harmonic minor `0 2 3 5 7 8 11`, Phrygian dominant `0 1 4 5 7 8 10`
* `resolveNote(note, key) → MidiPitch`, plus `spell(note, key) → NoteName`. Spelling is degree-based, so ♯2 in C is D♯ and never E♭.
* `ChordSpec → ChordTones` builds the chord in these steps:
  1. Choose the source scale: the borrowed scale if set, otherwise the key's scale.
  2. For applied chords, find the target root, then build V, IV or vii° in the target's major (or harmonic minor) context.
  3. Stack thirds up to the chosen type.
  4. Apply sus (replaces the 3rd), adds, omits and alterations.
  5. Pick the bass note from the inversion.
* `romanNumeral(chord, key)` handles case by quality, `°`, `ø`, `+`, figured bass, the `/x` suffix for applied chords and a borrowed-chord marker. `chordName()` gives absolute names (`Cmaj7/E`).
* `degreeColor(degree, scale, scheme)`:
  * *Diatonic-centric*: rotate the 7-colour wheel by the mode's offset from Ionian. Harmonic minor and Phrygian dominant use their parent modes (Aeolian and Phrygian).
  * *Major-centric*: compare the pitch to the major scale and return a stripe pair when it sits in between.
* `relativeTonic(fromKey, toScale)` returns the new tonic for relative changes. Note that harmonic minor and Phrygian dominant have no exact relative major; we map them via their parent mode and document the rule.
* `smartOctave(prevPitch, degree)` and the guitar shape finder (open, then E/A barre, then power chord) also live here. The shape finder is shared by playback and the tab export.

Test approach: table-driven. Every scale × degree × embellishment combination
has its expected pitches, name and Roman numeral. This is the
highest-leverage test suite in the project.

### 3.5 Arrangement engine (`motif_engine`)
`render(Song, range) → List<PerformanceEvent>` (tick, channel, pitch, velocity, duration). It's deterministic and pure.
* **Lead channels** play the voices' notes, applying ties and the track octave.
* **Harmony styles** are data-driven, for example:
  ```yaml
  id: piano-rh-quarters
  category: Piano
  voicing: {kind: close, notes: 3, dropBassIfMoreThan: 3}
  patterns:            # selected by beatsPerMeasure/beatUnit, fallback "*"
    "*": [{beat: every, length: 1}]
  ```
  The voicing algorithm places the chord tones closest to the track's continuous octave centre and keeps voice-leading between chords smooth. Guitar sounds go through the shape finder instead.
* **Bass styles** work the same way: a per-meter rhythm plus a note-selection rule (root, chord bass, walking through chord tones).
* **Drums**: a `DrumKit` holds `start`, `groove`, `fill1`, `fill2`, `break` and `pickup` bars per meter. Region logic follows §1.4 (fill every 8 bars, alternating fills, a pickup that looks ahead to the next region's kit).
* Swing (delaying off-beat 8ths) and the click track are added here.

Snapshot tests check `song.json → events.json`.

### 3.6 Audio (`motif_audio`), the main technical risk
* **Synthesis.** We synthesise all MIDI ourselves from SoundFonts, which gives sample-accurate timing and identical sound on every platform. The candidate is `dart_melty_soundfont`, a pure-Dart SF2 synth. It runs in a background isolate on native platforms. On web we use a Web Worker or AudioWorklet, or swap in a JS SF2 synth behind the same interface.
* **Output.** We stream PCM blocks to the device. Candidates are `flutter_soloud` (buffer streams; also decodes WAV/MP3 for audio tracks), `mp_audio_stream` and `flutter_pcm_sound`. Which one we use is decided in the M0 spike.
* **Transport.** A look-ahead scheduler renders ~50–100 ms ahead. The playhead is derived from frames actually played, not from a `Timer`. It also handles loop ranges and count-in.
* **Audio clips** are decoded once to PCM, then time-placed and mixed (offset, loop, split, volume, mute, solo). Waveform peaks are precomputed for drawing.
* **Sounds.** We ship permissively licensed SoundFonts: FluidR3_GM (MIT), MuseScore_General (MIT) or GeneralUser GS (licence must be checked). A `sounds.yaml` catalogue maps our names and categories to bank/program numbers and default octaves.

### 3.7 UI (`apps/motifforge`)
* **State**: Riverpod. `songProvider` (current `Song` + undo stack), `editorProvider` (cursor, selection, active voice, palette, modes), `transportProvider`, `settingsProvider` (persisted with `shared_preferences`).
* **Score view**: a custom `RenderBox`/`CustomPainter` per *system* (line), inside a virtualised `ListView`. Each system draws, from top to bottom:
  1. the measure bar with change flags
  2. the section labels
  3. the loop bar
  4. the melody staff, compact or chromatic, which grows vertically to fit the octaves used
  5. lyrics
  6. the chord staff
  7. the audio lane

  Hit-testing returns typed targets: note body, inner edge, outer edge, chord, flag, measure.
* **Palettes**: duration, note (1–7, rest, raise/lower, triplet, split/tie), voice panel, chord palette (degrees 1–7, type, inversion, sus, add/omit, alter, applied, borrow, Magic Chord). The top bar holds play/record/loop/click/volume and meter/key/tempo/band/lyrics/sections, plus zoom and horizontal zoom.
* **Keyboard**: a central `KeymapService` built on `HardwareKeyboard`. It needs *held-key state*, because Hookpad-style entry depends on what's held: ↑/↓ while typing a digit shifts the octave, and `.`/`,` add an accidental. The keymap is remappable and shown in a cheat-sheet overlay. Default bindings follow §1.
* **Dialogs**: key picker (circle of fifths + scale list + parallel/relative), meter, tempo (tap tempo), band editor (templates | tracks | sounds), measure operations (add before/after, key/meter/tempo/band change, line break, export range), lyrics side panel, audio clip panel.
* **Touch**: long-press selection, pinch zoom, an on-screen degree keypad and bottom-sheet palettes on tablets.

### 3.8 Files and interop (`motif_io`)
* **Native format**: `*.motif`, versioned JSON (optionally gzipped), with a migration chain `vN → vN+1`. Desktop and mobile autosave to the app documents folder; web uses IndexedDB plus download and upload.
* **Clipboard**: our own JSON payload. We also *import* Hookpad's clipboard JSON (`sd`, `octave`, `beat`, `duration`, `isRest`) so users can move ideas over. That's interoperability, not copying.
* **MIDI export**: our own SMF format-1 writer. It writes a conductor track (tempo, meter, key) and one track per band track (program, volume, octave).
* **MIDI import (stretch)**: quantise and key-detect, then convert to degrees.
* **MusicXML export**: melody + piano harmony with chord symbols and lyrics. Users can open it in MuseScore or Dorico straight away.
* **PDF (score, lead sheet, tab)**: in-app engraving with the `pdf` package and an SMuFL font (Bravura/Leland, OFL). We start with the lead sheet, which is the simplest layout, then the grand-staff score, then tab.
* **Audio export**: offline render (faster than real time) → WAV. MP3 comes via LAME over FFI on native and a JS encoder on web.
* **Lyrics**: Liang hyphenation with the TeX `hyph-en-us` patterns (check the licence; `hyphenatorx` on pub may already do this), plus the `-`, `_` and `_N_` override syntax.

### 3.9 Suggestions (`motif_suggest`)
We don't have Hooktheory's TheoryTab corpus, so we build our own:
* **Magic Chord**: a back-off n-gram model (up to 4-grams) over *key-relative* chord tokens such as `IV`, `V7/vi` or `bVII`. It's trained offline from openly licensed corpora: ChoCo (CC BY 4.0) and the de Clercq–Temperley Rock Corpus (licence to be checked). The model ships as a compact JSON table. A rule-based fallback (functional harmony) fills gaps, and later we can optionally learn from the user's own songs, locally.
* **Popular chords**: unigram frequencies per mode from the same model.
* **Tone sets / bass sets / search**: computed from `motif_theory`, by enumerating every chord spec the palette can build in the current key.
* **Progressions**: a hand-curated YAML library (I–V–vi–IV, ii–V–I, the Andalusian cadence…). Progressions can't be copyrighted, and the community can extend the list.

---

## 4. Roadmap

Each milestone ends with something usable and demo-able. Rough effort assumes 1–2 part-time developers.

### M0: Foundations (≈2 weeks)
- [ ] Workspace, packages, lints (`very_good_analysis` or `flutter_lints`), formatting, GitHub Actions (analyse + test + web build).
- [ ] `motif_theory`: scales, degree→pitch, spelling, chord builder, Roman numerals, with table tests.
- [ ] **Audio spike**: play an SF2 C-major scale with sample-accurate timing on Web, macOS, Windows, Linux, Android and iOS. Measure latency and CPU, then pick the output plugin. *Decision gate*: if `dart_melty_soundfont` can't keep up on web, use the JS synth there.
- [ ] Choose the licence and SoundFont, and write CONTRIBUTING and the clean-room rule.

### M1: Sketchpad MVP (≈4–6 weeks)
*Goal: you can write and hear a simple song.*
- [ ] Song model, commands, undo/redo, `.motif` save/load and autosave.
- [ ] Score view: one voice, compact staff, chord staff, measures, auto-extend, 8 bars per line.
- [ ] Keyboard entry: digits for notes and chords, `0` rest, durations `h j k l ;`, arrows, Shift selection, Backspace, Table mode, Smart Octave.
- [ ] Mouse: click to place the cursor, selection box, drag pitch, edge resize (outer and inner).
- [ ] Key and scale picker (9 scales, single key), meter (2–12), tempo.
- [ ] Chord palette, basic: degrees 1–7, triad/7th, inversions, `i` cycling, figured bass.
- [ ] Colours (diatonic-centric), Roman/absolute labels.
- [ ] Playback: default band (piano lead, piano RH quarters, dotted piano bass), play/stop, loop bar, click.

### M2: Full theory editing (≈4–6 weeks)
- [ ] All embellishments (9/11/13, sus, add/omit, alterations), `e` cycling, sticky palette.
- [ ] Borrowed and applied chords, with correct numeral and name rendering.
- [ ] Note accidentals (`.` `,` while typing or on a selection), chromatic staff, major-centric colours with stripes.
- [ ] Split (`/`), tie (`t`), triplets, Text entry mode with Alt-drag push and pull.
- [ ] Copy/cut/paste, the clipboard JSON, and Hookpad clipboard import.
- [ ] Measure operations: add before/after, delete range. Key, meter and tempo changes with flags. Parallel vs relative transposition. Swing. Tap tempo.
- [ ] Chord compatibility guides, line-break settings, horizontal and vertical zoom.
- [ ] 4 melody voices: active voice, visibility, play toggles, inactive-voice styles.

### M3: Band and arrangement (≈5–8 weeks; content heavy)
- [ ] Band editor: tracks (type, sound, volume, octave, mute), sound catalogue by category, templates (built-in and user), band changes.
- [ ] Harmony style DSL and ~10 starter styles. Voicing around the octave centre with voice leading.
- [ ] Guitar shape finder (open, barre, power chord).
- [ ] Bass style DSL and ~8 styles.
- [ ] Drum engine (basic, regular with fills, breaks, pickups) and ~10 kits × common meters.
- [ ] Mixer: per-channel mute, master volume.

### M4: Export (≈4–6 weeks)
- [ ] MIDI (format 1), whole song or a measure range.
- [ ] WAV offline render, then MP3.
- [ ] MusicXML.
- [ ] Lead sheet PDF, then score PDF, then guitar tab PDF.

### M5: Songwriting assistants (≈4 weeks)
- [ ] Sections, and the lyrics panel (syllabification, overrides, skip boxes, per section and per voice). Lyrics are shown in the staff and in the exports.
- [ ] Corpus pipeline (`tool/` scripts) → n-gram model. Magic Chord UI, popular chords, search, tone sets, bass sets, progressions library.

### M6: Input and media (≈4–6 weeks)
- [ ] MIDI controller input: `flutter_midi_command` on native, Web MIDI via `dart:js_interop`. Step entry maps pitch to degree; record mode uses count-in and quantise.
- [ ] Audio tracks: import, BPM/meter dialog, insert modes, move/resize/loop, offset, split, mute/solo/volume, waveform display.
- [ ] YouTube sync (web and mobile through `youtube_player_iframe`; desktop as available): markers with `[` `]`, test-sync mode.

### M7: Polish and release
- [ ] Phone layout, accessibility (screen-reader labels for notes and chords, high-contrast colours, colour-blind palette), i18n, onboarding tutorial song, docs site, store builds.
- Stretch: MIDI import, AI assistant (Aria-like) via an optional pluggable LLM backend, song "metrics", real-time collaboration.

### Feature parity checklist (guide section → milestone)
| Guide section | Milestone |
|---|---|
| Melody: add/delete, select, pitch, octave, duration | M1 |
| Melody: copy/paste, split, tie, non-diatonic, triplets | M2 |
| Melody: voices | M2 |
| Chords: add/delete, select, duration, inversions | M1 |
| Chords: copy/paste, split, tie, embellishments, non-diatonic | M2 |
| Magic Chord and smart chord options | M5 |
| Measures, key/scale, meter, tempo (single) | M1 |
| Key/meter/tempo changes, scale transposition | M2 |
| Sounds/instruments, band templates, band changes | M3 |
| Playback: harmony, guitar, bass, drums | M1 (defaults) → M3 (full) |
| Audio tracks | M6 |
| Export: MIDI, MP3 | M4 |
| Export: score, tab, lead sheet | M4 |
| Settings: entry mode, labels, colours, guides, smart octave, staff spacing | M1–M2 |
| Looping, line breaks | M1–M2 |
| Keyboard shortcuts (remappable) | M1 → ongoing |
| Lyrics | M5 |
| MIDI controller | M6 |
| YouTube sync | M6 |
| Copy and paste between projects | M2 |
| Undo/redo | M1 |

---

## 5. Quality strategy
* **Unit tests**: theory tables, model commands (each edit, in Table and Text mode), engine snapshots, and MIDI/MusicXML writers checked by round-trip parsing.
* **Golden tests** of rendered systems (colours, labels, flags) in light and dark themes.
* **Integration tests** that replay keystroke sequences, e.g. `1 2 3 ↓5 k l` → expected song JSON.
* **Performance budgets**: a 200-measure, 4-voice song scrolls at 60 fps; edit-to-repaint stays under 16 ms; audio has no dropouts at a 256-frame buffer on desktop.
* **Fixture songs** in `test/fixtures/` that exercise every feature, reused across exporter tests.

## 6. Key risks and mitigations
| Risk | Mitigation |
|---|---|
| Cross-platform audio timing and latency, especially web | M0 spike with a decision gate; own synth for determinism; a platform-specific backend behind one interface |
| Held-key entry semantics in Flutter | Prototype the keymap service in M0/M1, with tests for key-repeat and IME edge cases |
| Content volume (styles, drums, sounds) | Data-driven DSLs, a contributor guide, a style preview tool |
| PDF engraving complexity | Ship MusicXML first; start with the lead sheet; keep layout rules small |
| Chord-suggestion data licensing | Use only CC-BY or similar corpora; record the source and licence of every dataset in `assets/models/README` |
| Trademark or copyright confusion | Our own name and branding, clean-room docs, no Hookpad assets |

## 7. Open decisions
1. **Licence**: GPL-3.0 keeps forks open but makes App Store distribution awkward; Apache-2.0 or MIT maximise adoption. My suggestion is **MPL-2.0** or **Apache-2.0** if store releases matter.
2. **Platform priority**: start desktop and web (keyboard-first) and do tablets in M7, or design touch-first from day one?
3. **Hookpad interop**: is importing Hookpad's clipboard JSON wanted? It's cheap, and helps users migrate.
4. **Offline-only** vs optional sync later. This affects whether we design for CRDTs now.
5. **Audio output plugin**: decided by the M0 spike.
