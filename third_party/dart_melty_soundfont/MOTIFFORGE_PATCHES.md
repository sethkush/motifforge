# MotifForge patches

Vendored copy of [dart_melty_soundfont](https://pub.dev/packages/dart_melty_soundfont)
2.0.0 (MIT, see `LICENSE`), patched so it compiles for the web. Found by the
M0 audio spike (`tool/audio_bench`):

1. `lib/midi_file.dart`: the sentinel `0x7fffffffffffffff` can't be
   represented in JavaScript, so `dart compile js` (and Flutter web's JS
   build) failed. It's now a nullable `minTick`.
2. `lib/binary_reader.dart`: `dart:io` is now behind a conditional import
   (`read_file_io.dart` / `read_file_stub.dart`), so web builds don't pull it
   in. `fromFile` throws `UnsupportedError` on the web; use `fromByteData`.

Example asset (`TimGM6mbEdit.sf2`, GPL) and logo were removed. Upstream
these fixes and drop the vendored copy once a release includes them.
