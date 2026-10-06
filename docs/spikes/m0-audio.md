# M0 audio spike

**Question:** can we synthesise all playback ourselves in Dart, from
SoundFonts, fast enough and with stable timing on every target platform?
And which plugin should push the audio to the device?

**Status:** CPU side **passed** on the Dart VM, JavaScript and WebAssembly.
Playback is verified **headlessly end to end** on Linux desktop and web
(Chromium): the real app runs on a virtual display, plays through a virtual
sound card, and the recorded output is checked for silence and dropouts
(see "Headless test kit" below). Android runs on an emulator in CI. Real
phones are still worth a check before committing to the design.

## What was built

| Piece | Path | Purpose |
|---|---|---|
| Synthetic SoundFont | `tool/audio_bench/lib/synthetic_sf2.dart` | A tiny SF2 generated in code (harmonic tone + noise kit), so benchmarks need no licensed asset |
| Band workload | `tool/audio_bench/lib/workload.dart` | Default-band-like stream at 120 BPM: melody, 3-note chord per beat, dotted bass, drums with 8th hats, plus N extra "stress" voices |
| Benchmark | `dart run audio_bench:bench [file.sf2]` (VM), `tool/audio_bench/web/bench.dart` (browser) | Real-time factor and p99 render time per 512-frame chunk at 48 kHz |
| Spike app | `apps/audio_spike` | Flutter app: plays the workload via `mp_audio_stream`, shows render load, peak chunk time, underruns, plus a "tap note" button to judge latency |
| Patched synth | `third_party/dart_melty_soundfont` | See "Blockers found" |

## Results (cloud VM, 4 cores, no audio device)

Real-time factor = seconds of audio rendered per second of CPU on one core.
Above ~4× leaves comfortable headroom; budget per 512-frame chunk is
10.67 ms.

| Scenario | Dart VM | Chrome, Wasm | Chrome, JS |
|---|---|---|---|
| Band, reverb + chorus | 36× | 40× | 36× |
| Band + 16 voices, fx | 22× | 19× | 21× |
| Band + 32 voices, fx | 15× | 14× | 13× |
| Band + 64 voices, fx | 10× | 7.7× | 7.8× |
| Band, no fx | 109× | 70× | 72× |
| Band + 64 voices, no fx | 12× | 8.9× | 9.4× |

p99 chunk render time stayed ≤ 2.8 ms (budget 10.67 ms) in every scenario.
A real GM SoundFont (TimGM6mb, used locally only, not committed) gave
numbers within ±30% of the synthetic one, so the synthetic font is a fair
stand-in.

Takeaways:
- A pure-Dart synth is fast enough everywhere we measured, including the
  browser, with large headroom for 4 lead voices + harmony + bass + drums.
- Reverb + chorus cost roughly as much as 30 voices. We'll likely use a
  cheaper master reverb or make effects optional on low-end devices.

### Spike app in headless Chromium (Wasm build)

Played 30 s at 100 ms look-ahead with ~5% average render load on the UI
thread. The first run had 15 underruns, all in the first seconds while the
AudioWorklet started, and none after that. A second run (with an attempted
pre-fill) had 27. Headless Chrome uses software rendering and has no real
audio device, so these underrun counts aren't meaningful. They need checking
in a real browser.

## Headless test kit

| Platform | Command | What it does |
|---|---|---|
| Linux desktop | `tool/headless/run_linux.sh` | Xvfb display + PulseAudio null sink; runs `integration_test/ui_test.dart` (drives the buttons, screenshots) and `spike_test.dart` (5 playback scenarios + CPU benchmark) in profile mode; records the sink and analyses it |
| Web (Chromium) | `tool/headless/run_web.sh` | Builds each test as a web page, opens it in full Chromium via Playwright on Xvfb (so audio reaches the sink), screenshots on request, same recording analysis. `WEB_WASM=1` for Wasm |
| Android | `tool/headless/run_android.sh` | Same tests on an emulator or device (CI starts an emulator); screenshots through the integration-test binding |

`tool/headless/analyze_audio.py` lines the recording up with the test's
`SPIKE_MARK` log lines and, for each playback window, reports the sounding
length, level and **dropouts** (runs of digital silence ≥ 1 ms). The app's
own underrun counter and the recording agree, which validates both. CI runs
all three (`.github/workflows/headless.yml`, `android.yml`); results appear
in the job summary and as artifacts (logs, screenshots, FLAC recordings).

## Results: Android emulator (CI, API 34 x86_64, profile build)

| Look-ahead ms | Stress voices | Load % | Underruns / 20 s | Device start delay ms |
|---|---|---|---|---|
| 100 | 0 | 1.4 | 3 (first start only) | 0 |
| 100 | 64 | 5.9 | 0 | 10 |
| 50 | 0 | 1.4 | 0 | 3 |
| 30 | 0 | 1.4 | 0 | 4 |
| 20 | 0 | 1.5 | 528 | 2101 |

CPU benchmark on the emulator: 14–79× real time with effects, 16–180×
without. AAudio starts almost instantly; 30 ms look-ahead is clean, 20 ms is
below the emulator's burst size. The UI test (drive the buttons, four
screenshots) passes on the emulator's phone-size screen.

## Findings from the headless runs

1. **Wall-clock pumping is wrong.** Pushing audio by the wall clock filled
   the device buffer while the device was still starting, so steady-state
   latency became the whole buffer (~0.5 s). Fixed with **backpressure**:
   the ring buffer is sized to the target latency and we push until the
   device says it's full (`mp_audio_stream` returns -1 when full on native).
2. **Linux/PulseAudio needs an explicit latency request.** Without one the
   device starts 0.9–2.2 s late. With 20 ms requested (`PULSE_LATENCY_MSEC`)
   it starts in 5–55 ms and plays cleanly at 30 ms look-ahead and above
   (20 ms: occasional underrun). The real engine must configure a low
   device period itself.
3. **Web needs synthesis off the UI thread.** The web plugin's push has no
   "full" signal, so web still paces by the wall clock, and rendering on the
   UI thread gave 3–21 underruns per 8 s scenario in Chromium (a few short
   dropouts in the recording). Plan: render in an AudioWorklet or Worker
   (Wasm) behind the `AudioBackend` interface.
4. **Phone-size layout**: the lazy list doesn't build off-screen rows, so
   tests (and later, UI code) must scroll things into view. `PHONE_LAYOUT=true`
   reproduces the phone layout on desktop.
5. **Clipboard can be unavailable** (headless browser): "Copy results" now
   falls back to a selectable dialog.

## Blockers found (and fixed)

`dart_melty_soundfont` 2.0.0 didn't compile for the web:
1. A 64-bit integer literal in `midi_file.dart` broke `dart compile js`. This
   also broke `flutter build web`, which always builds a JS fallback.
2. `binary_reader.dart` imported `dart:io` unconditionally.

Fix: a vendored, patched copy in `third_party/dart_melty_soundfont`
(MIT), wired in with `dependency_overrides` in the root `pubspec.yaml`.
Details in `MOTIFFORGE_PATCHES.md`. **Follow-up:** send both fixes upstream
and drop the vendored copy once a release has them.

## Output plugin candidates

| Plugin | Platforms | Notes |
|---|---|---|
| `mp_audio_stream` 0.3 | Android, iOS, macOS, Windows, Linux, Web | Tiny push API (`init`, `push(Float32List)`, `stat()` with underrun counts). Used in the spike. Web uses an AudioWorklet. |
| `flutter_soloud` 5.x | Android, iOS, macOS, Windows, Linux, Web | Heavier (native build hooks). Has PCM buffer streams **and** WAV/MP3 decoding, which we need for audio tracks in M6. |
| `flutter_pcm_sound` 3.x | Android, iOS, macOS | **Ruled out:** no web, Windows or Linux. |

**Provisional choice:** `mp_audio_stream` for synth output, behind a
`AudioBackend` interface in `motif_audio`. Re-evaluate `flutter_soloud` in
M6 when audio tracks need decoding. If one plugin can do both well, it's
simpler to use one.

## Still to do: real-device runs

The headless runs cover behaviour and catch regressions. Real hardware is
still worth one manual pass before we lock in the design. Run `apps/audio_spike` on each platform with the defaults (100 ms look-ahead,
reverb on), then with 64 stress voices, then with look-ahead lowered until
underruns appear. Record the numbers:

| Platform | Device | Underruns / 60 s (default) | Load % | Lowest clean look-ahead | Tap-note latency feel |
|---|---|---|---|---|---|
| Chrome (Wasm) | | | | | |
| Firefox | | | | | |
| Safari | | | | | |
| macOS | | | | | |
| Windows | | | | | |
| Linux | | | | | |
| Android | | | | | |
| iOS / iPadOS | | | | | |

```sh
cd apps/audio_spike
flutter run -d chrome --wasm          # or -d macos / windows / linux / <device id>
flutter build web --wasm --no-web-resources-cdn   # static build in build/web
```

## Implications for the design

- The plan's architecture holds: synthesise ourselves, push PCM, take the
  playhead from frames pushed.
- On native, rendering moves to a background isolate (the spike renders on
  the UI isolate, which is the worst case). On the web there are no isolates.
  If device runs show UI jank causing underruns, synthesis moves into a Web
  Worker or AudioWorklet (Wasm), which the `AudioBackend` interface allows.
- Note previews while typing need low latency, so the transport should
  render previews with a shorter look-ahead than playback. Device runs
  decide the numbers.
