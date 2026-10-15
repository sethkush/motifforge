import 'dart:async';
import 'dart:typed_data';

import 'package:mp_audio_stream/mp_audio_stream.dart';

import 'render_core.dart';
import 'model.dart';

const _isWeb = bool.fromEnvironment('dart.library.js_interop');

/// Feeds a [RenderCore] into `mp_audio_stream` on a 5 ms timer, in whatever
/// isolate it's created in. Pure Dart (no Flutter), so it also runs inside the
/// background audio isolate.
///
/// Native: **backpressure**. The device ring buffer is sized to the target
/// latency and each tick pushes until the device reports it full; a rejected
/// chunk is kept and retried. Web: the plugin's push has no "full" signal,
/// so it paces by the wall clock (used only for the UI-thread comparison
/// mode; the background web engine has its own worklet).
class StreamPump {
  StreamPump(this.core, this.mode, {AudioStream? stream})
    : _stream = stream ?? getAudioStream();

  final RenderCore core;
  final String mode;
  final AudioStream _stream;
  final _clock = Stopwatch();
  Timer? _timer;
  int _initResult = -1;
  int _accepted = 0;
  Float32List? _pending;

  bool get running => _timer != null;

  int start() {
    final s = core.settings;
    _initResult = _stream.init(
      bufferMilliSec: _isWeb ? s.lookaheadMs * 4 : s.lookaheadMs,
      waitingBufferMilliSec: _isWeb ? s.lookaheadMs ~/ 2 : s.lookaheadMs ~/ 4,
      channels: 2,
      sampleRate: RenderCore.sampleRate,
    );
    _stream.resume(); // web: must follow a user gesture
    _stream.resetStat();
    _clock
      ..reset()
      ..start();
    _fill();
    _timer = Timer.periodic(const Duration(milliseconds: 5), (_) => _fill());
    return _initResult;
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _clock.stop();
    _stream.uninit();
  }

  void _fill() {
    if (_isWeb) {
      final target =
          (_clock.elapsedMicroseconds * RenderCore.sampleRate / 1e6).round() +
          core.settings.lookaheadMs * RenderCore.sampleRate ~/ 1000;
      while (_accepted < target) {
        _stream.push(core.render());
        _accepted += RenderCore.chunkFrames;
      }
      return;
    }
    for (var i = 0; i < 64; i++) {
      final chunk = _pending ?? core.render();
      if (_stream.push(chunk) != 0) {
        _pending = chunk; // full: retry this exact chunk next tick
        return;
      }
      _pending = null;
      _accepted += RenderCore.chunkFrames;
    }
  }

  SpikeStats stats() {
    final stat = _stream.stat();
    final wallMs = _clock.elapsedMicroseconds / 1000;
    final lookahead = core.settings.lookaheadMs;
    return core.stats(
      mode: mode,
      initResult: _initResult,
      playedFrames: _accepted,
      wallSeconds: wallMs / 1000,
      underruns: stat.exhaust,
      overflows: stat.full,
      // Native: the buffer is full at the end, so wall time minus audio
      // accepted (less the buffer) is how long the device took to start.
      startDelayMs: _isWeb
          ? 0
          : (wallMs - (_accepted / RenderCore.sampleRate * 1000 - lookahead))
                .clamp(0, double.infinity)
                .toDouble(),
    );
  }
}
