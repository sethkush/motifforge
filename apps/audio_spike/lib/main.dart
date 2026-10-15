import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'spike_engine.dart';

/// M0 audio spike. Plays the band workload through dart_melty_soundfont and
/// mp_audio_stream, and shows the numbers we need to choose the audio stack:
/// device underruns, render load, and how a tapped note feels (latency).
/// The automated version of this lives in integration_test/spike_test.dart.
void main() => runApp(const SpikeApp());

/// Wraps the whole app so tests can capture screenshots on platforms where
/// the integration-test screenshot API isn't available (desktop).
final screenshotKey = GlobalKey(debugLabel: 'screenshot');

class SpikeApp extends StatelessWidget {
  const SpikeApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'MotifForge audio spike',
    theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
    builder: (context, child) =>
        RepaintBoundary(key: screenshotKey, child: child),
    home: const SpikePage(),
  );
}

class SpikePage extends StatefulWidget {
  const SpikePage({super.key});

  @override
  State<SpikePage> createState() => _SpikePageState();
}

class _SpikePageState extends State<SpikePage> {
  AudioEngine? _engine;
  SpikeSettings _settings = const SpikeSettings();
  SpikeStats? _stats;
  Timer? _refresh;
  String _status = 'Stopped';
  bool _busy = false;
  final _benchLines = <String>[];
  bool _benchRunning = false;

  bool get _running => _engine?.running ?? false;

  Future<void> _start() async {
    setState(() {
      _busy = true;
      _status = 'Starting…';
    });
    var engine = _engine;
    if (engine == null ||
        engine.mode == 'ui-thread' && _settings.background ||
        engine.mode != 'ui-thread' && !_settings.background) {
      engine?.dispose();
      engine = _engine = createEngine(background: _settings.background);
    }
    int rc;
    try {
      rc = await engine.start(_settings);
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _status = 'start failed: $e';
        });
      }
      return;
    }
    _refresh = Timer.periodic(
      const Duration(milliseconds: 250),
      (_) => setState(() => _stats = engine!.stats ?? _stats),
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _status = rc == 0 ? 'Playing' : 'init failed ($rc)';
    });
  }

  Future<void> _stop() async {
    _refresh?.cancel();
    _refresh = null;
    final engine = _engine;
    if (engine != null && engine.running) {
      setState(() => _busy = true);
      _stats = await engine.stop();
    }
    if (mounted) {
      setState(() {
        _busy = false;
        _status = 'Stopped';
      });
    }
  }

  void _change(SpikeSettings s) {
    setState(() => _settings = s);
    _engine?.update(s);
  }

  Future<void> _runBenchmark() async {
    await _stop();
    setState(() {
      _benchRunning = true;
      _benchLines.clear();
    });
    await for (final r in runCpuBenchmark()) {
      setState(
        () => _benchLines.add(
          '${r.label}: ${r.realTimeFactor.toStringAsFixed(1)}x realtime, '
          'p99 ${r.p99ChunkMs.toStringAsFixed(2)} ms',
        ),
      );
    }
    setState(() => _benchRunning = false);
  }

  String _report() {
    final s = _stats;
    return [
      'MotifForge audio spike results',
      'Platform: ${platformDescription()}',
      if (s != null) ...[
        'Rendering: ${s.mode}',
        'Settings: ${s.settings.toJson()}',
        'Audio rendered: ${s.audioSeconds.toStringAsFixed(1)} s',
        'Average render load: ${s.loadPercent.toStringAsFixed(1)} %',
        'Peak chunk render: ${s.peakChunkMs.toStringAsFixed(2)} ms',
        'Underruns: ${s.underruns}, buffer-full drops: ${s.overflows}',
      ],
      if (_benchLines.isNotEmpty) ...['CPU benchmark:', ..._benchLines],
      'Crackles heard? ___   Tap-note latency feel? ___',
    ].join('\n');
  }

  Future<void> _copyReport() async {
    final text = _report();
    try {
      await Clipboard.setData(ClipboardData(text: text));
    } on PlatformException {
      // Clipboard can be unavailable (permissions, some browsers): show the
      // text so it can be selected and copied by hand.
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Copy these results'),
          content: SingleChildScrollView(child: SelectableText(text)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Results copied')));
  }

  @override
  void dispose() {
    _refresh?.cancel();
    _engine?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final running = _running;
    final s = _stats;
    return Scaffold(
      appBar: AppBar(title: const Text('Audio spike')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(_status, style: Theme.of(context).textTheme.headlineSmall),
          Text(platformDescription()),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(
                onPressed: _busy ? null : (running ? _stop : _start),
                child: Text(running ? 'Stop' : 'Start'),
              ),
              OutlinedButton(
                onPressed: running ? () => _engine?.tapNote() : null,
                child: const Text('Tap note (latency check)'),
              ),
              OutlinedButton(
                onPressed: _benchRunning ? null : _runBenchmark,
                child: Text(
                  _benchRunning ? 'Benchmarking…' : 'Run CPU benchmark',
                ),
              ),
              FilledButton.tonal(
                onPressed: _copyReport,
                child: const Text('Copy results'),
              ),
            ],
          ),
          SwitchListTile(
            title: const Text('Band pattern'),
            subtitle: const Text('Off = silence except tapped notes'),
            value: _settings.band,
            onChanged: (v) => _change(_settings.copyWith(band: v)),
          ),
          SwitchListTile(
            title: const Text('Render in background (applies on restart)'),
            subtitle: const Text(
              'Isolate on native, Web Worker + AudioWorklet on web. '
              'Off = UI thread (for comparison).',
            ),
            value: _settings.background,
            onChanged: running
                ? null
                : (v) => _change(_settings.copyWith(background: v)),
          ),
          SwitchListTile(
            title: const Text('Reverb + chorus (applies on restart)'),
            value: _settings.effects,
            onChanged: running
                ? null
                : (v) => _change(_settings.copyWith(effects: v)),
          ),
          ListTile(
            title: Text('Extra stress voices: ${_settings.stressVoices}'),
            subtitle: Slider(
              value: _settings.stressVoices.toDouble(),
              max: 64,
              divisions: 8,
              onChanged: (v) =>
                  _change(_settings.copyWith(stressVoices: v.round())),
            ),
          ),
          ListTile(
            title: Text(
              'Look-ahead: ${_settings.lookaheadMs} ms (applies on restart)',
            ),
            subtitle: Slider(
              value: _settings.lookaheadMs.toDouble(),
              min: 20,
              max: 300,
              divisions: 14,
              onChanged: running
                  ? null
                  : (v) => _change(_settings.copyWith(lookaheadMs: v.round())),
            ),
          ),
          const Divider(),
          if (s != null) ...[
            _stat('Rendering on', s.mode),
            _stat('Audio rendered', '${s.audioSeconds.toStringAsFixed(1)} s'),
            _stat(
              'Average render load',
              '${s.loadPercent.toStringAsFixed(1)} %',
            ),
            _stat(
              'Peak chunk render',
              '${s.peakChunkMs.toStringAsFixed(2)} ms '
                  '(budget ${s.chunkBudgetMs.toStringAsFixed(2)} ms)',
            ),
            _stat('Device underruns (buffer ran dry)', '${s.underruns}'),
            _stat(
              'Device start delay (estimate)',
              '${s.startDelayMs.round()} ms',
            ),
            _stat('Buffer-full pushes (backpressure)', '${s.overflows}'),
          ],
          if (_benchLines.isNotEmpty) ...[
            const Divider(),
            Text(
              'CPU benchmark (5 s of audio per line)',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            for (final line in _benchLines)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(line),
              ),
          ],
        ],
      ),
    );
  }

  Widget _stat(String label, String value) =>
      ListTile(dense: true, title: Text(label), trailing: Text(value));
}
