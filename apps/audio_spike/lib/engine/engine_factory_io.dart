import 'dart:async';
import 'dart:isolate';

import 'engine.dart';
import 'render_core.dart';
import 'stream_pump.dart';

AudioEngine createBackgroundEngine() => IsolateEngine();

/// Native: a long-lived background isolate owns the synth **and** the audio
/// device (`mp_audio_stream` is plain FFI, so it works from any isolate).
/// The UI isolate only sends commands and receives statistics, so UI jank
/// can't starve the audio.
class IsolateEngine implements AudioEngine {
  Isolate? _isolate;
  SendPort? _tx;
  ReceivePort? _rx;
  Completer<int>? _started;
  Completer<SpikeStats>? _stopped;
  SpikeStats? _latest;
  bool _running = false;

  @override
  String get mode => 'isolate';

  @override
  bool get running => _running;

  @override
  SpikeStats? get stats => _latest;

  Future<SendPort> _ensureIsolate() async {
    if (_tx != null) return _tx!;
    final rx = ReceivePort();
    _rx = rx;
    final ready = Completer<SendPort>();
    rx.listen((Object? m) {
      if (m is SendPort) {
        ready.complete(m);
        return;
      }
      final msg = (m! as Map).cast<String, Object?>();
      switch (msg['type']) {
        case 'started':
          _started?.complete(msg['initResult']! as int);
        case 'stats':
          _latest = SpikeStats.fromJson(
            (msg['stats']! as Map).cast<String, Object?>(),
          );
        case 'stopped':
          _latest = SpikeStats.fromJson(
            (msg['stats']! as Map).cast<String, Object?>(),
          );
          _stopped?.complete(_latest);
      }
    });
    _isolate = await Isolate.spawn(
      _audioIsolateMain,
      rx.sendPort,
      debugName: 'audio',
    );
    return _tx = await ready.future;
  }

  @override
  Future<int> start(SpikeSettings settings) async {
    final tx = await _ensureIsolate();
    _started = Completer<int>();
    _latest = null;
    _running = true;
    tx.send({'type': 'start', 'settings': settings.toJson()});
    return _started!.future;
  }

  @override
  Future<SpikeStats> stop() {
    _stopped = Completer<SpikeStats>();
    _running = false;
    _tx!.send({'type': 'stop'});
    return _stopped!.future;
  }

  @override
  void update(SpikeSettings settings) =>
      _tx?.send({'type': 'update', 'settings': settings.toJson()});

  @override
  void tapNote() => _tx?.send({'type': 'tap'});

  @override
  void dispose() {
    _isolate?.kill(priority: Isolate.immediate);
    _rx?.close();
    _isolate = null;
    _tx = null;
  }
}

/// Entry point of the audio isolate.
void _audioIsolateMain(SendPort toMain) {
  final rx = ReceivePort();
  toMain.send(rx.sendPort);
  StreamPump? pump;
  Timer? statsTimer;
  rx.listen((Object? m) {
    final msg = (m! as Map).cast<String, Object?>();
    switch (msg['type']) {
      case 'start':
        statsTimer?.cancel();
        pump?.stop();
        final settings = SpikeSettings.fromJson(
          (msg['settings']! as Map).cast<String, Object?>(),
        );
        final p = StreamPump(RenderCore(settings), 'isolate');
        pump = p;
        final rc = p.start();
        toMain.send({'type': 'started', 'initResult': rc});
        statsTimer = Timer.periodic(
          const Duration(milliseconds: 250),
          (_) => toMain.send({'type': 'stats', 'stats': p.stats().toJson()}),
        );
      case 'stop':
        statsTimer?.cancel();
        final p = pump;
        if (p == null) return;
        final s = p.stats();
        p.stop();
        pump = null;
        toMain.send({'type': 'stopped', 'stats': s.toJson()});
      case 'update':
        pump?.core.update(
          SpikeSettings.fromJson(
            (msg['settings']! as Map).cast<String, Object?>(),
          ),
        );
      case 'tap':
        pump?.core.tapNote();
    }
  });
}
