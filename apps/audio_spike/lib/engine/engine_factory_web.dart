import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

import 'engine.dart';
import 'render_core.dart';

AudioEngine createBackgroundEngine() => WorkerEngine();

/// Web: the synth runs in a Web Worker (`synth_worker.js`, compiled from
/// worker/synth_worker.dart) and posts audio straight to an AudioWorklet
/// (`spike_worklet.js`) over a MessageChannel. The page's main thread only
/// sends commands and receives statistics, so UI work can't starve the audio.
class WorkerEngine implements AudioEngine {
  web.AudioContext? _ctx;
  web.Worker? _worker;
  web.AudioWorkletNode? _node;
  Completer<int>? _started;
  Completer<SpikeStats>? _stopped;
  SpikeStats? _latest;
  bool _running = false;
  bool _moduleLoaded = false;

  @override
  String get mode => 'web-worker';

  @override
  bool get running => _running;

  @override
  SpikeStats? get stats => _latest;

  @override
  Future<int> start(SpikeSettings settings) async {
    // The AudioContext must be created/resumed from a user gesture (Start).
    final ctx = _ctx ??= web.AudioContext(
      web.AudioContextOptions(
        sampleRate: RenderCore.sampleRate.toDouble(),
        latencyHint: 'interactive'.toJS,
      ),
    );
    final resumed = ctx.resume().toDart;
    if (!_moduleLoaded) {
      await ctx.audioWorklet.addModule('spike_worklet.js').toDart;
      _moduleLoaded = true;
    }
    final node = web.AudioWorkletNode(
      ctx,
      'spike-processor',
      web.AudioWorkletNodeOptions(
        numberOfInputs: 0,
        outputChannelCount: [2.toJS].toJS,
      ),
    );
    node.connect(ctx.destination);
    _node = node;

    final channel = web.MessageChannel();
    final toWorklet = JSObject()
      ..['type'] = 'port'.toJS
      ..['port'] = channel.port1;
    node.port.postMessage(toWorklet, [channel.port1].toJS);

    final worker = _worker ??= _createWorker();
    _started = Completer<int>();
    _latest = null;
    _running = true;
    final msg = JSObject()
      ..['type'] = 'start'.toJS
      ..['settings'] = settings.toJson().jsify()
      ..['port'] = channel.port2;
    worker.postMessage(msg, [channel.port2].toJS);
    await resumed;
    return _started!.future;
  }

  web.Worker _createWorker() {
    final worker = web.Worker('synth_worker.js'.toJS);
    worker.onmessage = ((web.MessageEvent e) {
      final d = e.data as JSObject;
      final type = (d['type'] as JSString).toDart;
      final stats = SpikeStats.fromJson(
        (d['stats'].dartify()! as Map).cast<String, Object?>(),
      );
      _latest = stats;
      switch (type) {
        case 'started':
          _started?.complete(0);
        case 'stopped':
          _stopped?.complete(stats);
      }
    }).toJS;
    worker.onerror = ((web.Event e) {
      _started?.completeError(StateError('synth worker failed: $e'));
    }).toJS;
    return worker;
  }

  void _send(String type, [SpikeSettings? settings]) {
    final msg = JSObject()..['type'] = type.toJS;
    if (settings != null) msg['settings'] = settings.toJson().jsify();
    _worker?.postMessage(msg);
  }

  @override
  Future<SpikeStats> stop() async {
    _stopped = Completer<SpikeStats>();
    _running = false;
    _send('stop');
    final stats = await _stopped!.future;
    _node?.disconnect();
    _node = null;
    return stats;
  }

  @override
  void update(SpikeSettings settings) => _send('update', settings);

  @override
  void tapNote() => _send('tap');

  @override
  void dispose() {
    _worker?.terminate();
    _worker = null;
    _node?.disconnect();
    unawaited(_ctx?.close().toDart);
    _ctx = null;
  }
}
