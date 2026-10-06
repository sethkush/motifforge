# audio_spike

M0 throwaway app. It plays a band-like workload through the pure-Dart
SoundFont synth and `mp_audio_stream`, and shows render load, peak chunk
time and device underruns. Use it to fill in the device table in
[`docs/spikes/m0-audio.md`](../../docs/spikes/m0-audio.md).

```sh
flutter run -d chrome --wasm     # or -d macos / windows / linux / <device id>
```

On the web, press **Start** (a user gesture is needed to start audio), then
**Tap note** to judge latency.
