import 'dart:async';

import 'engine_factory_stub.dart'
    if (dart.library.js_interop) 'engine_factory_web.dart'
    if (dart.library.io) 'engine_factory_io.dart'
    as platform;
import 'model.dart';
import 'render_core.dart';
import 'stream_pump.dart';

export 'model.dart';

/// Plays the spike workload. Implementations differ in where audio is
/// rendered: the UI thread ([UiThreadEngine]), a background isolate (native)
/// or a Web Worker feeding an AudioWorklet (web).
abstract class AudioEngine {
  /// `ui-thread`, `isolate` or `web-worker`.
  String get mode;
  bool get running;

  /// Opens the device and starts playing. Completes with the device init
  /// result (0 = success).
  Future<int> start(SpikeSettings settings);

  /// Stops and completes with the final statistics.
  Future<SpikeStats> stop();

  /// Applies settings that change while playing (stress voices, band).
  void update(SpikeSettings settings);

  void tapNote();

  /// Latest statistics (background engines report every 250 ms).
  SpikeStats? get stats;

  /// Releases the isolate / worker / audio context.
  void dispose();
}

/// Creates the engine for [background] on this platform.
AudioEngine createEngine({required bool background}) =>
    background ? platform.createBackgroundEngine() : UiThreadEngine();

/// Renders on the UI isolate (the original spike design), for comparison.
class UiThreadEngine implements AudioEngine {
  StreamPump? _pump;

  @override
  String get mode => 'ui-thread';

  @override
  bool get running => _pump?.running ?? false;

  @override
  Future<int> start(SpikeSettings settings) async {
    final pump = StreamPump(RenderCore(settings), mode);
    _pump = pump;
    return pump.start();
  }

  @override
  Future<SpikeStats> stop() async {
    final pump = _pump!;
    final s = pump.stats();
    pump.stop();
    return s;
  }

  @override
  void update(SpikeSettings settings) => _pump?.core.update(settings);

  @override
  void tapNote() => _pump?.core.tapNote();

  @override
  SpikeStats? get stats => _pump?.stats();

  @override
  void dispose() {
    if (running) _pump!.stop();
  }
}
