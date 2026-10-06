# MotifForge — Project Plan

MotifForge aims to be a **feature-for-feature, behaviour-for-behaviour clone of
Hooktheory's Hookpad**, built in Flutter/Dart. "Same" covers the workflow,
layout, keyboard shortcuts, entry rules and musical results. The code,
artwork, sounds, text, data and names are all made independently. You write
melodies and chords as **scale degrees and Roman numerals**, hear them played
by an auto-arranged band, and export to MIDI, notation and audio.

Sources: the Hookpad User Guide (v2.1.0) and the screenshots in it. §0 covers
how we can clone as closely as the law allows. §1 lists every feature the
guide describes, in our own words.

---

## 0. Parity target and legal boundaries

**Target:** a Hookpad user can sit down at MotifForge and work from the same
muscle memory: same screen layout, same shortcuts, same entry behaviour, same
playback results. They can also bring their work across.

> Not legal advice. Before a public release, have a lawyer review the points
> below, particularly the visual design and the naming.

### 0.1 What we replicate
Functional elements, which copyright generally doesn't protect:
* **Features, workflows and behaviour**: entry rules, edge-drag behaviour, Smart Octave, voicing rules, drum-region logic, and so on.
* **UI layout and information architecture**: toolbar order, palette positions, how the staffs are stacked, which dialogs exist and what they contain.
* **Keyboard shortcuts and menu structure.**
* **Colour-coding by scale degree**, which does a functional job. We keep the same hue order and choose our own exact colour values.
* **Data formats, for interoperability**: Hookpad's clipboard JSON, and its "Save To Disk" file if we can get sample files.

### 0.2 What we make ourselves
These are expressive works, so they are protected:

| Hookpad has | MotifForge uses |
|---|---|
| Source code | Written from scratch from our own specs. We never read or decompile Hookpad's client JS. |
| Logo, icons, illustrations | Our own icons, or an open icon set (Lucide, Material Symbols) |
| Fonts | OFL-licensed fonts, e.g. a libre serif for Roman numerals |
| Instrument samples | CC0 / CC-BY samples (e.g. Salamander Grand Piano, VSCO 2 CE, CC0 drum kits) packed as SF2/SF3 |
| Style and drum patterns, templates | Programmed by us. Generic rhythms are fine, but we don't transcribe theirs note for note. |
| Help text, tooltips, tutorials, videos | Written and recorded by us |
| TheoryTab database | Open corpora plus our own community library (§3.9, M9) |
| The Aria AI model | Our own model, trained on open data |
| Names: Hookpad, Hooktheory, TheoryTab, Aria, Magic Chord | Our own names, e.g. "Suggest Chord" and "Song Library" |

### 0.3 Risk notes
1. **Look and feel.** Copying layout and behaviour is low risk. A pixel-identical skin (exact colours, typography, chrome) raises trade-dress and unfair-competition risk. So: same layout, our own visual styling.
2. **Trademarks.** Don't use their names in the app name, icon or store listing. Saying "imports from Hookpad" or "works like Hookpad" is normally fine as nominative use.
3. **Terms of service.** We use Hookpad only as an ordinary user. No decompiling, no scraping TheoryTab, no calling their private APIs.
4. **Patents.** Search for patents held by Hooktheory before release. This hasn't been checked yet.

### 0.4 Clean-room process
* **Specs.** People write behaviour specs in `docs/spec/<area>.md`, in their own words, from the public guide and from using Hookpad normally (screenshots and screen recordings). Every rule comes with **conformance cases**: a starting state, an input sequence, and the expected result.
* **Tests.** Conformance cases become automated tests in `packages/motif_conformance`. Its `report` command shows the pass rate per area (the parity dashboard).
* **The rule** is "never copy their code, text or assets", not "different people must write the spec and the code". A small team can do both.

### 0.5 Source material still needed
The guide doesn't cover everything. To reach full parity we need:
1. The **keyboard shortcuts page**, which is separate from the guide.
2. **Current Hookpad UI captures** of every screen. Partly covered: the guide's screenshots and a published review are distilled into `docs/spec/layout.md`. Still missing:: main view, every palette state, every dialog, every menu, the settings panel, and mobile/tablet layouts. The guide's screenshots mix the classic UI and the Hookpad 2 UI. We target the current one.
3. The **undocumented panels**: Aria, Guides, Metrics, Sections, Chord Chart, Mix.
4. **Content lists**: sound names and categories, band templates, harmony/bass/drum style names, the progressions list, the scope of chord search. We recreate the content itself.
5. A sample **"Save To Disk" file**, and clipboard payloads that cover chords, accidentals, triplets and voices.
6. The exact durations for the `'` and `b` keys, and the edge cases around them.

---

## 1. Feature inventory (what Hookpad does)

### 1.1 Melody
| Feature | Behaviour |
|---|---|
| Note entry | Click in the melody staff, then type `1`–`7` to add scale degrees (`0` = rest). Backspace/Delete removes notes like a text editor does. |
| Octave placement | **Smart Octave** (default) places a new note in the octave closest to the previous note. When it's off, the note goes in the same octave as its neighbour. Holding ↑/↓ while typing a digit forces the octave above/below. 5 octaves are supported. |
| Selection | Rubber-band box, Ctrl/Cmd-click, Shift-click, Shift+←/→. |
| Pitch edit | Drag vertically, or ↑/↓ to step through the scale. Shift+↑/↓ moves a whole octave. There are also Raise/Lower buttons (step, half step, octave). |
| Duration | Drag a note edge. From the *outer* edge the neighbour resizes with it. From the *inner* edge the note eats into its neighbour. In Text mode, Alt-drag pushes or pulls every following note. Keys `h j k l ; ' b` choose the entry duration (¼, ½, 1, 2, 4 beats, plus longer values); which ones are available depends on the meter. |
| Split / tie | `/` toggles split mode (click to cut a note). `t` ties selected adjacent notes that have the same pitch. |
| Accidentals | `.` raises and `,` lowers by a half step. Holding either key while typing a digit enters the note already altered. |
| Voices | 4 melody voices; Ctrl+1…4 switches between them. Each voice has its own lyrics, instrument, octave and volume. Inactive voices can be drawn translucent, solid or outlined (colour per voice); backtick cycles the style. There are per-voice visible and play toggles. |
| Triplets | "Make Triplet" splits a quarter into 3 eighth-triplets, or a half into 3 quarter-triplets. There are no 16th triplets. |

### 1.2 Chords
| Feature | Behaviour |
|---|---|
| Entry | Type `1`–`7` in the chord staff to add diatonic chords; Backspace deletes. The palette also has a rest slot (`0`) and a magic/★ slot (`8`). |
| Selection / move | Drag in an empty area or along a chord's top/bottom edge to select a range. Dragging from a chord's middle moves it. Ctrl/Shift-click and Shift+arrows also select. |
| Duration / split / tie | Same as notes. Tie needs adjacent chords with the same root. |
| Inversion | Root, 1st, 2nd, and 3rd (7th chords only). `i` cycles through them. Shown as figured bass: none, ⁶, ⁶₄, ⁷, ⁶₅, ⁴₃, ⁴₂. |
| Type | Triad (5), 7, 9, 11, 13. `e` cycles through embellishment combinations. |
| Sus | sus2, sus4 |
| Add / omit | add4, add6, add9, no3, no5 |
| Alterations | ♭5, ♯5, ♭9, ♯9, ♯11, ♭13 (enabled only where they make sense) |
| Applied (secondary) | V of, IV of, vii° of (`d` shortcut). You pick the function, then type the target chord. For example, "V of" + `2` gives V/ii. |
| Borrowed | Pick a parallel mode from a dropdown and the chord is built from that mode's scale on the same tonic. The non-diatonic panel's shortcut is `n`. |
| Sticky palette | When nothing is selected, palette settings apply to the *next* chord you enter. |
| Labels | Roman numeral is the primary label and the absolute chord name is secondary. A setting swaps them. |
| Magic Chord / Magic Bass | Suggests the chord (or bass) at the cursor, ranked by how often it follows the preceding chords in the TheoryTab song database. |
| Other smart tools | Popular chords in the current key; chord search by name; **Tone sets** (chords containing chosen notes); **Bass sets** (alternative chords over the same bass note); **Progressions** (insert common progressions). |

### 1.3 Song structure
| Feature | Behaviour |
|---|---|
| Measures | The song grows automatically as you write. You can add N measures before or after a selection, select measures from the bar above the staff, and delete several at once. A handle at the end of the song (and +/− buttons) adds or removes measures. The measure bar invites you to "drag to add measures, key/meter/band/tempo changes". |
| Key / scale | The default is C major. Tonic is picked on a circle of fifths. Scales: Major, Minor, Dorian, Phrygian, Lydian, Mixolydian, Locrian, Harmonic Minor, Phrygian Dominant. |
| Scale change type | **Parallel** (default) keeps degrees and changes pitches: I in C major becomes i in C minor. **Relative** keeps pitches and changes degrees: C major → A minor, so I becomes III. In Relative mode the tonic picker is greyed out. |
| Key changes | Placed at a measure and shown as flags. |
| Meter | 2, 3, 4, 5, 6, 9 or 12 beats per measure. Compound meters (3/6/9/12) have a "beat unit = 3" option where 3 beats are felt as one, and tempo follows it. Meter changes apply to a measure range, until the next change, or to the end of the song. They show as flags you can select and delete. |
| Tempo | Slider, tap tempo (`q`), swing checkbox, tempo changes. |
| Band changes | Instrumentation can change at a measure. |
| Sections | Named sections such as "Verse 1", shown above the measure bar. Lyrics are organised by section. |
| Line breaks | 8 measures per line by default. Enter forces a break. Settings: N per line, auto-fit to window, one long line, or manual breaks only. |
| Looping | A loop bar above the staff; click it to enable or disable. |

### 1.4 Band, playback and sound
* **Tracks** have a *type* (lead1–4, harmony, bass, drums), a *sound*, a *volume* and an *octave*. Lead octave is ±1 in steps. For harmony and bass it is a continuous voicing centre, measured in octaves.
* You can add, remove and mute tracks. The sound list is filtered by track type and grouped into categories (Piano, Orchestral, Vocals, Synth, Plugged Synth, Percussive…). The band dialog has three columns: Templates | Band Tracks | Sounds.
* **Band templates** come built in, and users can save their own. Applying one replaces the current band, after a confirmation. In the free tier, band edits revert when the project is saved; we have no paywall, so we leave that out.
* There are **7 playback channels**: 4 leads, harmony, bass and drums. Each can be muted from the volume menu.
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
Import WAV or MP3 by drag-and-drop or File → Import Audio File. A dialog asks for the clip's BPM and meter (with tap tempo) and can auto-add measures. You insert the clip at the start, at the cursor, or after the previous clip, then drag to move it. The bottom corner resizes the clip and the top corner loops it. Controls: lane zoom, waveform zoom, sync offset (`<<< << < > >> >>>` nudges), volume, mute, solo, loop, split, delete. There's also a "delete unused files" command.

### 1.6 Export
Each export covers the whole song (File → Export), or just the selected measures (Export button in the measure panel).
* **Score PDF**: a melody staff plus a 2-staff piano harmony part. It spells notes for the key (♯2 → D♯ in C, not E♭).
* **Guitar tab PDF** with fingerings for chords and melody.
* **Lead sheet PDF**.
* **MIDI** (SMF format 1), one track per band track, including volume and octave.
* **MP3**.

### 1.7 Settings
* **Entry mode**: *Table* (default) overwrites and allows gaps. *Text* inserts, pushing later notes along, and fills gaps with rests. The toggle is in the top-right corner.
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
* Lyrics are per section and per voice. The panel shows a note count for each section.

### 1.9 Input, sync, editing
* **MIDI controller**: a played pitch is converted to a scale degree in the current key (step entry). In **record mode** you play in time and the notes are quantised.
* **YouTube sync**: attach a URL, then set start and end markers with `[` and `]` while it plays (the span must be a whole number of measures). A "test the sync" mode follows along, `p` plays or pauses the video, and markers can be nudged. Used for transcription, and leads into "add my analysis to TheoryTab".
* **Clipboard**: `c`/`v` (with or without Ctrl/Cmd) copy and paste. "Paste from clipboard" works across projects using a JSON payload like `{"notes":[{"sd":"1","octave":0,"beat":1,"duration":1,"isRest":false}],"chords":[],"fp":"…"}`. Browsers that can't read the clipboard get a fallback paste box.
* **Undo/redo**: `z`/`y`, 20 levels.

### 1.10 UI chrome visible in the screenshots
* **Hookpad 2 header**:
  * Left: Meter, Key, Tempo, Band, Lyrics, Sections
  * Centre: Aria (beta)
  * Right: Guides, YouTube, Audio Track, Metrics
  * Also zoom and horizontal zoom (−/+), the song title, and the entry-mode toggle.
* **Transport**: Play (Space), Record, Loop, Click, Volume, Mix (`m`), Open (`o`), Save (`s`), Export, Chord Chart, Settings.
* **Menus**:
  * File: New `n`, Open `o`, Save `s`, Save As, Export ▸ (Score/Tab/Lead/MIDI/MP3), Open From Disk, Save To Disk, Import Audio File
  * Edit: Undo `z`, Redo `y`, Cut `x`, Copy `c`, Paste `v`, Paste From Clipboard, Delete `del`
  * Also MIDI, Settings, Help
* **Palette area** (sits under the header and changes with the staff the cursor is in):
  * Duration ladder (h j k l ; ' b, Add/Split/Tie)
  * "Add a note (1–7, 0)" or "Add a chord in C Major" swatches showing the absolute name and the key hint
  * Raise/Lower/Octave/Half-step buttons
  * Voice / Visible / Play / Inactive-coloring panel
  * Chord groups: Type (e), Inv (i), Sus, Add/Omit, Alter, Sec (d), Borrow
* **Account features** (out of scope as a service; see M8 for our equivalent): login, cloud project list, activation and paywall, TheoryTab transfer.
* **Undocumented, need captures**: Aria, Guides, Metrics, Chord Chart, Mix panel.

---

## 2. Goals

1. **Full parity** with everything in §1, including Aria, Guides, Metrics, cloud projects and sharing, and a community song-analysis library. Each has an open equivalent; the only things we don't ship are the protected items in §0.2.
2. **Same muscle memory**: identical default shortcuts and layout. Users can remap keys, but the defaults match Hookpad.
3. **Interoperability**: read and write Hookpad's clipboard JSON, import "Save To Disk" files, and import and export MIDI and MusicXML.
4. **Platforms**: **Android first** (owner's priority), then Web as an installable PWA (as Hookpad is), macOS, Windows, Linux and iPadOS, with a phone layout. Works fully offline; the cloud is optional.
5. **Everything open**: code, sounds (CC0/CC-BY), styles, drum patterns, progressions and suggestion models are open data that the community can extend.

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
│  ├─ motif_io/                 # MIDI / MusicXML / WAV / MP3 / PDF / clipboard / Hookpad import
│  ├─ motif_suggest/            # chord suggestions, tone/bass sets, progressions, AI co-writer client
│  ├─ motif_conformance/        # runs the conformance cases in docs/spec, parity report
│  └─ motif_cloud_client/       # optional sync / sharing client (M8)
├─ apps/
│  ├─ motifforge/               # Flutter UI
│  └─ audio_spike/              # M0 throwaway: on-device audio test app
├─ server/                      # optional self-hostable backend (M8–M9)
├─ assets/
│  ├─ soundfonts/               # CC0/CC-BY SF2/SF3
│  ├─ styles/                   # harmony/bass style definitions
│  ├─ drums/                    # drum kit pattern definitions
│  ├─ templates/                # band templates
│  └─ models/                   # chord n-gram tables
├─ docs/
│  ├─ PLAN.md
│  └─ spec/                     # clean-room behaviour specs + conformance cases
├─ third_party/                 # vendored, patched dependencies (licence + patch notes)
└─ tool/                        # audio_bench (M0), corpus pipelines, SF3 packing
```

Everything below `motif_audio` is **pure Dart**. Theory, model, engine and IO
can therefore be unit-tested quickly without Flutter, and reused on the server.

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
  List<Voice> voices;               // exactly 4, each with notes + lyrics
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
`Command` with a label for the undo menu. Undo/redo is a persistent stack of
`Song` snapshots. For parity the default depth is **20**, with a setting to
raise it. Edits are written against an `EditContext` that carries the entry
mode (Table or Text), Smart Octave and the current palette settings.

### 3.4 Theory (`motif_theory`)
* `Scale` holds a semitone pattern per mode:
  * Major `0 2 4 5 7 9 11`, Dorian `0 2 3 5 7 9 10`, Phrygian `0 1 3 5 7 8 10`
  * Lydian `0 2 4 6 7 9 11`, Mixolydian `0 2 4 5 7 9 10`, Minor `0 2 3 5 7 8 10`
  * Locrian `0 1 3 5 6 8 10`, Harmonic minor `0 2 3 5 7 8 11`, Phrygian dominant `0 1 4 5 7 8 10`
* `resolveNote(note, key) → MidiPitch`, plus `spell(note, key) → NoteName`. Spelling is degree-based, so ♯2 in C is D♯ and never E♭.
* `ChordSpec → ChordTones` builds the chord in these steps:
  1. Choose the source scale: the borrowed scale if set, otherwise the key's scale.
  2. For applied chords, find the target root, then build V, IV or vii° in the target's context.
  3. Stack thirds up to the chosen type.
  4. Apply sus (replaces the 3rd), adds, omits and alterations.
  5. Pick the bass note from the inversion.
* `romanNumeral(chord, key)` handles case by quality, `°`, `ø`, `+`, figured bass, the `/x` suffix for applied chords and a borrowed-chord marker. `chordName()` gives absolute names (`Cmaj7/E`).
* `degreeColor(degree, scale, scheme)`:
  * *Diatonic-centric*: rotate the 7-colour wheel (red, orange, yellow, green, blue, purple, pink) by the mode's offset from Ionian. Harmonic minor and Phrygian dominant use their parent modes.
  * *Major-centric*: compare the pitch to the major scale and return a stripe pair when it sits in between.
* `relativeTonic(fromKey, toScale)` returns the new tonic for relative changes. Harmonic minor and Phrygian dominant have no exact relative scale; their behaviour must be checked against Hookpad and captured as conformance cases.
* `smartOctave(prevPitch, degree)` and the guitar shape finder (open, then E/A barre, then power chord) also live here. The shape finder is shared by playback and the tab export.

Test approach: table-driven. Every scale × degree × embellishment combination
has its expected pitches, name and Roman numeral.

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
* **Bass styles** work the same way: a per-meter rhythm plus a note-selection rule.
* **Drums**: a `DrumKit` holds `start`, `groove`, `fill1`, `fill2`, `break` and `pickup` bars per meter. Region logic follows §1.4.
* Swing and the click track are added here.

For parity we aim to match Hookpad's style catalogue one for one: the same
number of styles, the same characters and the same meter coverage. Each style
is programmed by us. Snapshot tests check `song.json → events.json`.

### 3.6 Audio (`motif_audio`), the main technical risk
* **Synthesis.** We synthesise all MIDI ourselves from SoundFonts, which gives sample-accurate timing and identical sound on every platform. The candidate is `dart_melty_soundfont`, a pure-Dart SF2 synth. It runs in a background isolate on native platforms. On web we use a Web Worker or AudioWorklet, or swap in a JS SF2 synth behind the same interface.
* **Output.** We stream PCM blocks to the device. Candidates are `flutter_soloud`, `mp_audio_stream` and `flutter_pcm_sound`. Which one we use is decided in the M0 spike.
* **Transport.** A look-ahead scheduler renders ~50–100 ms ahead. The playhead is derived from frames actually played, not from a `Timer`. It also handles loop ranges and count-in.
* **Audio clips** are decoded once to PCM, then time-placed and mixed. Waveform peaks are precomputed for drawing.
* **Sounds.** These come from high-quality CC0/CC-BY multisample libraries (Salamander Grand, VSCO 2 CE, CC0 drum kits…) packed into SF3. FluidR3_GM or MuseScore_General (MIT) cover the gaps. A `sounds.yaml` catalogue mirrors Hookpad's categories.

### 3.7 UI (`apps/motifforge`)
Same **layout** as Hookpad 2 (§1.10) with our own skin: icons, fonts, exact colours and spacing.
* **State**: Riverpod. `songProvider` (current `Song` + undo stack), `editorProvider` (cursor, selection, active voice, palette, modes), `transportProvider`, `settingsProvider`.
* **Score view**: a custom `RenderBox`/`CustomPainter` per *system* (line), inside a virtualised `ListView`. Each system draws, from top to bottom:
  1. the section labels
  2. the measure bar with change flags
  3. the loop bar
  4. the melody staff, compact or chromatic
  5. lyrics
  6. the chord staff, with Roman numeral and name labels
  7. the audio lane

  The song-end handle sits after the last system. Hit-testing returns typed targets: note body, inner edge, outer edge, chord, flag, measure, end handle.
* **Palettes**: arranged exactly as described in §1.10, switching between note mode and chord mode with the cursor's staff.
* **Keyboard**: a central `KeymapService` built on `HardwareKeyboard`. It tracks *held keys*, because entry depends on what's held: ↑/↓ while typing a digit shifts the octave, `.`/`,` add an accidental, and Alt-drag pushes notes. Default bindings are Hookpad's; users can remap them.
* **Dialogs**: key picker (circle of fifths + scale list + parallel/relative), meter (with beat unit), tempo (tap tempo, swing), band editor (Templates | Band Tracks | Sounds), measure operations, lyrics side panel, sections, audio file panel and BPM dialog, YouTube attach, export, settings, Mix, Chord Chart.
* **Touch**: long-press selection, pinch zoom, an on-screen degree keypad and bottom-sheet palettes on tablets.

### 3.8 Files and interop (`motif_io`)
* **Native format**: `*.motif`, versioned JSON with a migration chain `vN → vN+1`. Desktop and mobile autosave to the app documents folder; web uses IndexedDB. Open From Disk and Save To Disk match Hookpad's menu items.
* **Hookpad clipboard**: always **read** it (`sd`, `octave`, `beat`, `duration`, `isRest`, plus chord fields once we have samples). **Write** it too, if a black-box test shows Hookpad accepts our payload. The `fp` field is opaque, so if Hookpad requires it to be valid, our support is read-only.
* **Hookpad "Save To Disk" import**: needs sample files (§0.5).
* **MIDI export**: our own SMF format-1 writer. It writes a conductor track and one track per band track. **MIDI import**: quantise and key-detect, then convert to degrees.
* **MusicXML export.**
* **PDF (score, lead sheet, tab)**: in-app engraving with the `pdf` package and an SMuFL font (Bravura/Leland, OFL).
* **Audio export**: offline render → WAV, then MP3 via LAME over FFI on native and a JS encoder on web.
* **Lyrics**: Liang hyphenation with the TeX `hyph-en-us` patterns (check the licence), plus the `-`, `_` and `_N_` override syntax.

### 3.9 Suggestions and AI (`motif_suggest`)
Hookpad's data features run on Hooktheory's private **TheoryTab** database: crowd-sourced, key-relative transcriptions of real songs. We can't use it, so we build the equivalent in stages:
1. **Bootstrap**: a back-off n-gram model over key-relative chord tokens (`IV`, `V7/vi`, `bVII`…). It's trained offline from openly licensed corpora such as ChoCo (CC BY 4.0) and others whose licences we've checked. Every dataset's source and licence is recorded in `assets/models/README.md`.
2. **Community library** (M9): our own open, TheoryTab-style library of song analyses that users contribute under CC BY-SA, directly from MotifForge's YouTube-sync workflow. It retrains the model over time.
* **Suggest Chord / Suggest Bass** (the Magic Chord equivalent) and **Popular Chords** use the model.
* **Tone sets, bass sets and search** are computed from `motif_theory`.
* **Progressions** are a curated YAML library.
* **AI co-writer** (the Aria equivalent; scope comes from the M0 captures): a pluggable backend. It can be a local symbolic model trained on open data, or the user's own LLM API key. It produces chord, melody and harmonisation suggestions as normal edit commands, so they can be undone.

---

## 4. Roadmap

Each milestone ends with something usable, and its conformance suite runs in CI.

### M0: Foundations and spec (≈2–3 weeks)
- [ ] Collect the source material in §0.5 (still needed from Hookpad users).
- [x] First specs in `docs/spec/` (melody, chords, structure, display, keymap) with conformance cases tagged documented / observed / assumed.
- [x] Workspace, lints, GitHub Actions (format, analyze, test, parity report, JS + Wasm web builds), conformance harness (`packages/motif_conformance`).
- [x] `motif_theory`: scales, key spelling, degree→pitch, Smart Octave placement, chord builder (types, sus, add/omit, alterations, applied, borrowed, inversions), chord symbols, Roman numerals, colour slots, relative tonic. Table tests for every scale.
- [~] **Audio spike** (`docs/spikes/m0-audio.md`): CPU side passed on the Dart VM, JS and Wasm. Two web blockers in `dart_melty_soundfont` found and patched (`third_party/`). Output plugin provisionally `mp_audio_stream`. **Open:** device runs on every platform.
- [x] Licence: **ISC** for all code (see `LICENSE`). Bundled assets keep their own licences and are listed in `assets/LICENSES.md`.
- [x] CONTRIBUTING with the clean-room rules, asset-licence ledger.

### M1: Core editor (≈4–6 weeks)
*Goal: you can write and hear a simple song in a Hookpad-identical layout.*
- [ ] Song model, commands, undo/redo (20), `.motif` save/load and autosave.
- [ ] Score view: one voice, compact staff, chord staff, measures, auto-extend, end handle, 8 bars per line.
- [ ] Keyboard entry per the keymap spec: digits, `0`, durations, arrows, Shift selection, Backspace, Table mode, Smart Octave.
- [ ] Mouse: cursor, selection box, drag pitch, edge resize (outer and inner), chord move.
- [ ] Header, transport and palette layout. Key and scale picker, meter, tempo.
- [ ] Chord palette: degrees, rest, triad/7th, inversions (`i`), figured bass.
- [ ] Diatonic-centric colours, Roman/absolute labels.
- [ ] Playback with the default band, loop bar, click.

### M2: Full theory editing (≈4–6 weeks)
- [ ] All embellishments, `e`/`d`/`n` shortcuts, sticky palette, borrowed and applied chords.
- [ ] Note accidentals, chromatic staff, major-centric colours with stripes.
- [ ] Split, tie, triplets, Text entry mode with Alt-drag.
- [ ] Copy/cut/paste, Paste From Clipboard with a fallback dialog, reading Hookpad clipboard JSON.
- [ ] Measure operations; key, meter, tempo changes with flags; parallel vs relative transposition; swing; tap tempo.
- [ ] Chord compatibility guides, line-break settings, zoom and horizontal zoom.
- [ ] 4 voices: active, visible, play, inactive-colouring.

### M3: Band and arrangement (≈6–8 weeks; content heavy)
- [ ] Band editor (Templates | Band Tracks | Sounds), sound catalogue, templates, band changes, Mix panel.
- [ ] Harmony style DSL and a full style catalogue matching Hookpad's coverage.
- [ ] Guitar shape finder, bass styles, drum engine (basic, regular, breaks, pickups) with full kit coverage.
- [ ] Sample sourcing and SF3 packing pipeline.

### M4: Export (≈4–6 weeks)
- [ ] MIDI, WAV/MP3, MusicXML, lead sheet, score and tab PDFs; whole song or a measure range.

### M5: Songwriting assistants (≈4 weeks)
- [ ] Sections, lyrics panel (syllabification, overrides, skip boxes, per section and per voice).
- [ ] Corpus pipeline → n-gram model. Suggest Chord/Bass, popular chords, search, tone sets, bass sets, progressions.
- [ ] Chord Chart, Guides and Metrics panels (per the M0 captures).

### M6: Input and media (≈4–6 weeks)
- [ ] MIDI controller (step entry and record mode), via `flutter_midi_command` on native and Web MIDI on web.
- [ ] Audio tracks (the full feature set in §1.5).
- [ ] YouTube sync (`youtube_player_iframe`; desktop via webview where available).
- [ ] MIDI import, Hookpad "Save To Disk" import.

### M7: Polish and release
- [ ] Tablet and phone layouts, accessibility (screen-reader labels, colour-blind palette), i18n, our own tutorial song and docs site, store builds, legal review (§0.3).

### M8: Cloud (optional, self-hostable)
- [ ] Accounts, cloud project list (Open/Save/Save As like Hookpad), share-by-link read-only player, embeddable player.
- [ ] `server/`: a Dart backend (e.g. Serverpod or Dart Frog) or PocketBase. Anyone can self-host it, and we host a public instance.

### M9: Community library and AI co-writer
- [ ] Song analysis library: publish from the YouTube-sync workflow, browse and search, CC BY-SA licensing, moderation.
- [ ] Retrain the suggestion model on the library.
- [ ] AI co-writer (the Aria equivalent).

### Feature parity checklist (guide section → milestone)
| Guide section | Milestone |
|---|---|
| Melody: add/delete, select, pitch, octave, duration | M1 |
| Melody: copy/paste, split, tie, non-diatonic, triplets, voices | M2 |
| Chords: add/delete, select, duration, inversions | M1 |
| Chords: copy/paste, split, tie, embellishments, non-diatonic | M2 |
| Magic Chord / Magic Bass and smart chord options | M5 |
| Measures, key/scale, meter, tempo (single) | M1 |
| Key/meter/tempo changes, scale transposition | M2 |
| Sounds/instruments, band templates, band changes | M3 |
| Playback: harmony, guitar, bass, drums | M1 (defaults) → M3 (full) |
| Audio tracks | M6 |
| Export: score, tab, lead sheet, MIDI, MP3 | M4 |
| Settings: entry mode, labels, colours, guides, smart octave, staff spacing | M1–M2 |
| Looping, line breaks | M1–M2 |
| Keyboard shortcuts | M1 → ongoing (conformance) |
| Lyrics | M5 |
| MIDI controller | M6 |
| YouTube sync | M6 |
| TheoryTab transfer → community library | M9 |
| Copy and paste between projects | M2 |
| Undo/redo | M1 |
| Aria / Guides / Metrics / Chord Chart / Mix | M9 / M5 / M5 / M5 / M3 |
| Accounts and cloud projects | M8 |

---

## 5. Quality strategy
* **Conformance suite**: generated from `docs/spec/`. It's the single measure of parity.
* **Unit tests**: theory tables, model commands (Table and Text mode), engine snapshots, and writers checked by round-trip parsing.
* **Golden tests** of rendered systems and palettes, in light and dark themes.
* **Integration tests** that replay keystroke sequences against the full app.
* **Performance budgets**: a 200-measure, 4-voice song scrolls at 60 fps; edit-to-repaint stays under 16 ms; audio has no dropouts at a 256-frame buffer on desktop.

## 6. Key risks and mitigations
| Risk | Mitigation |
|---|---|
| Cross-platform audio timing, especially web | M0 spike with a decision gate; own synth; a platform backend behind one interface |
| Held-key entry semantics in Flutter | Prototype the keymap service early, with conformance tests |
| Content volume (sounds, styles, drums) | Data-driven DSLs, a sample-packing pipeline, a contributor guide |
| Suggestion quality without TheoryTab | Open corpora now, the community library later, a rule-based fallback |
| Undocumented behaviour | §0.5 captures, then conformance cases; treat mismatches as bugs |
| PDF engraving | MusicXML first, then the lead sheet, then the score, then tab |
| Legal (trade dress, trademarks, ToS) | §0 rules, our own skin and names, legal review before launch |

## 7. Open decisions
1. **Platform priority**: web and desktop first (Hookpad is a web app), tablets in M7?
2. **Backend stack** for M8: Serverpod / Dart Frog (all Dart) or PocketBase (fastest to ship).
3. **Product naming** for features: "Suggest Chord", "Song Library", "Co-writer"…
