// Web Worker entry point: the web audio engine's synth thread.
//
// Compiled separately to web/synth_worker.js by tool/build_synth_worker.sh
// (Flutter's web build only compiles lib/main.dart). Receives commands from
// the page, renders with RenderCore, and posts audio straight to the
// AudioWorklet over a MessagePort, keeping `lookaheadMs` of audio queued
// based on the worklet's "played" reports (backpressure).
import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:audio_spike/engine/model.dart';
import 'package:audio_spike/engine/render_core.dart';
import 'package:web/web.dart' as web;

@JS('self')
external web.DedicatedWorkerGlobalScope get _self;

RenderCore? _core;
web.MessagePort? _out;
Timer? _pump;
Timer? _statsTimer;
final _clock = Stopwatch();
int _pushed = 0;
int _played = 0;
int _underruns = 0;
double? _startDelayMs;

void main() {
  _self.onmessage = ((web.MessageEvent e) {
    final d = e.data as JSObject;
    switch ((d['type'] as JSString).toDart) {
      case 'start':
        _start(
          SpikeSettings.fromJson(
            (d['settings'].dartify()! as Map).cast<String, Object?>(),
          ),
          d['port'] as web.MessagePort,
        );
      case 'stop':
        _stop();
      case 'update':
        _core?.update(
          SpikeSettings.fromJson(
            (d['settings'].dartify()! as Map).cast<String, Object?>(),
          ),
        );
      case 'tap':
        _core?.tapNote();
    }
  }).toJS;
}

void _start(SpikeSettings settings, web.MessagePort out) {
  _stop();
  _core = RenderCore(settings);
  _out = out;
  _pushed = 0;
  _played = 0;
  _underruns = 0;
  _startDelayMs = null;
  out.onmessage = ((web.MessageEvent m) {
    final s = m.data as JSObject;
    _played = (s['played'] as JSNumber).toDartInt;
    _underruns = (s['underruns'] as JSNumber).toDartInt;
    _startDelayMs ??= _clock.elapsedMicroseconds / 1000;
    _fill();
  }).toJS;
  _clock
    ..reset()
    ..start();
  _fill();
  // The worklet's reports drive refills; the timer is a safety net.
  _pump = Timer.periodic(const Duration(milliseconds: 4), (_) => _fill());
  _statsTimer = Timer.periodic(
    const Duration(milliseconds: 250),
    (_) => _post('stats'),
  );
  _post('started');
}

void _fill() {
  final core = _core;
  final out = _out;
  if (core == null || out == null) return;
  final target = core.settings.lookaheadMs * RenderCore.sampleRate ~/ 1000;
  while (_pushed - _played < target) {
    final pcm = core.render().toJS;
    // Transfer the buffer (no copy) to the worklet.
    out.postMessage(pcm, [pcm['buffer'] as JSObject].toJS);
    _pushed += RenderCore.chunkFrames;
  }
}

void _stop() {
  final out = _out;
  if (_core == null || out == null) return;
  _pump?.cancel();
  _statsTimer?.cancel();
  _post('stopped');
  final reset = JSObject()..['t'] = 'reset'.toJS;
  out.postMessage(reset);
  out.close();
  _core = null;
  _out = null;
}

void _post(String type) {
  final core = _core;
  if (core == null) return;
  final stats = core.stats(
    mode: 'web-worker',
    initResult: 0,
    playedFrames: _played,
    wallSeconds: _clock.elapsedMicroseconds / 1e6,
    underruns: _underruns,
    overflows: 0,
    startDelayMs: _startDelayMs ?? 0,
  );
  final msg = JSObject()
    ..['type'] = type.toJS
    ..['stats'] = stats.toJson().jsify();
  _self.postMessage(msg);
}
