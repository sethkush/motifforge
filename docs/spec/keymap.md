# Default keymap

These are the default bindings; users can remap them. Hookpad has a separate
keyboard-shortcuts page that we don't have yet, so this list only covers
what the guide and screenshots show. Unless noted, shortcuts work with or
without Ctrl/Cmd (`c` and Ctrl+C both copy), which the guide states for
edit commands.

Notation used in edit cases: a key name (`1`, `k`, `Backspace`, `Up`), a
chord with `+` (`Shift+Up`, `Ctrl+2`), `hold:<key> <key>` for pressing the
second key while holding the first, `click:<button>` and `dialog:<name> …`
for UI actions.

| Keys | Action | Context | Source |
|---|---|---|---|
| `1`–`7` | Add note / chord on that degree | melody / chord staff | documented |
| `0` | Add rest | both | observed (palette label) |
| `8` | Suggest chord (★ slot) | chord staff | observed (palette label) |
| hold `Up`/`Down` + digit | Enter note an octave higher/lower | melody | documented |
| hold `.`/`,` + digit | Enter note a half step higher/lower | melody | documented |
| `Backspace` / `Delete` | Delete before / after cursor, or the selection | both | documented |
| `Up` / `Down` | Selected notes up/down a scale step | melody | documented |
| `Shift+Up` / `Shift+Down` | Selected notes up/down an octave | melody | documented |
| `.` / `,` | Raise / lower selected notes a half step | melody | documented |
| `Shift+Left` / `Shift+Right` | Extend selection one item | both | documented |
| `h` `j` `k` `l` `;` `'` `b` | Entry duration ¼, ½, 1, 2, 4 beats, longer, longer | both | documented |
| `/` | Toggle split mode | both | documented |
| `t` | Tie selected | both | documented |
| `i` | Cycle inversion | chord | documented |
| `e` | Cycle embellishments | chord | documented |
| `d` | Applied ("secondary") chord function | chord | observed (palette label "Sec. (d)") |
| `n` | Non-diatonic options | chord | observed (palette label "Non-diatonic (n)") |
| `Ctrl+1` … `Ctrl+4` | Active melody voice | melody | documented |
| `` ` `` | Cycle inactive-voice style | melody | documented |
| `c` / `x` / `v` | Copy / cut / paste | both | documented |
| `z` / `y` | Undo / redo (20 levels) | global | documented |
| `Space` | Play / stop | global | observed (toolbar label "Play (sb)") |
| `m` | Mix panel | global | observed (toolbar label) |
| `o` / `s` / `n` | Open / save / new | global | observed (menu labels) |
| `q` | Tap tempo (while the tap dialog is open) | dialog | documented |
| `Enter` | Line break at this measure | global | documented |
| `p` | Play / pause attached YouTube video | global | documented |
| `[` / `]` | Set YouTube sync start / end marker | sync mode | documented |
| `Tab` | Insert a "skip notes" box | lyrics editor | documented |
| `+` / `-` | Grow / shrink a skip box | lyrics editor | documented |

## Conflicts to resolve

- `n` appears as both "New" (File menu) and "Non-diatonic" (chord palette).
  (assumed) In the chord staff `n` is Non-diatonic and New needs Ctrl/Cmd.
- `b` is both a duration key and the flat glyph in note input; there's no
  conflict because `,` (not `b`) lowers notes.
- `.`/`,` lower/raise vs. Hookpad's "hold while entering" behaviour need a
  held-key model (see `KeymapService` in `docs/PLAN.md` §3.7).

```conformance
id: keymap.durations
kind: edit
status: documented
source: "guide: Note Duration"
cases:
  - given: {voice: ["|"], meter: 4}
    keys: ["k", "1", "l", "2", ";", "3"]
    expect: {voice: ["1/1", "2/2", "3/4", "|"]}
```

## Open questions

The keyboard-shortcuts page should answer: Ctrl/Cmd variants for every key,
arrow-key cursor movement between notes and staffs, switching between melody
and chord staff, selecting all, zoom, and loop shortcuts.
