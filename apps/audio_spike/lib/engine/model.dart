// Pure Dart (no Flutter): shared by the UI isolate, the audio isolate and
// the web worker.

/// Settings for one playback run.
class SpikeSettings {
  const SpikeSettings({
    this.lookaheadMs = 100,
    this.stressVoices = 0,
    this.effects = true,
    this.band = true,
    this.background = true,
  });

  factory SpikeSettings.fromJson(Map<String, Object?> j) => SpikeSettings(
    lookaheadMs: (j['lookaheadMs']! as num).toInt(),
    stressVoices: (j['stressVoices']! as num).toInt(),
    effects: j['effects']! as bool,
    band: j['band']! as bool,
    background: (j['background'] as bool?) ?? true,
  );

  final int lookaheadMs;
  final int stressVoices;
  final bool effects;
  final bool band;

  /// Render audio off the UI thread (isolate on native, Web Worker + AudioWorklet
  /// on web). False renders on the UI thread, kept for comparison.
  final bool background;

  SpikeSettings copyWith({
    int? lookaheadMs,
    int? stressVoices,
    bool? effects,
    bool? band,
    bool? background,
  }) => SpikeSettings(
    lookaheadMs: lookaheadMs ?? this.lookaheadMs,
    stressVoices: stressVoices ?? this.stressVoices,
    effects: effects ?? this.effects,
    band: band ?? this.band,
    background: background ?? this.background,
  );

  Map<String, Object> toJson() => {
    'lookaheadMs': lookaheadMs,
    'stressVoices': stressVoices,
    'effects': effects,
    'band': band,
    'background': background,
  };
}

/// Snapshot of playback statistics.
class SpikeStats {
  const SpikeStats({
    required this.settings,
    required this.mode,
    required this.initResult,
    required this.audioSeconds,
    required this.wallSeconds,
    required this.loadPercent,
    required this.peakChunkMs,
    required this.chunkBudgetMs,
    required this.underruns,
    required this.overflows,
    required this.startDelayMs,
  });

  factory SpikeStats.fromJson(Map<String, Object?> j) => SpikeStats(
    settings: SpikeSettings.fromJson(j),
    mode: j['mode']! as String,
    initResult: (j['initResult']! as num).toInt(),
    audioSeconds: (j['audioSeconds']! as num).toDouble(),
    wallSeconds: (j['wallSeconds']! as num).toDouble(),
    loadPercent: (j['loadPercent']! as num).toDouble(),
    peakChunkMs: (j['peakChunkMs']! as num).toDouble(),
    chunkBudgetMs: (j['chunkBudgetMs']! as num).toDouble(),
    underruns: (j['underruns']! as num).toInt(),
    overflows: (j['overflows']! as num).toInt(),
    startDelayMs: (j['startDelayMs']! as num).toDouble(),
  );

  final SpikeSettings settings;

  /// Where audio was rendered: `ui-thread`, `isolate` or `web-worker`.
  final String mode;

  /// 0 when the audio device opened successfully.
  final int initResult;
  final double audioSeconds;
  final double wallSeconds;
  final double loadPercent;
  final double peakChunkMs;
  final double chunkBudgetMs;
  final int underruns;

  /// Native: pushes the device rejected because its buffer was full
  /// (backpressure working). Web UI-thread mode: dropped pushes.
  final int overflows;

  /// How long the device took to start consuming audio.
  final double startDelayMs;

  Map<String, Object> toJson() => {
    ...settings.toJson(),
    'mode': mode,
    'initResult': initResult,
    'audioSeconds': _r(audioSeconds),
    'wallSeconds': _r(wallSeconds),
    'loadPercent': _r(loadPercent),
    'peakChunkMs': _r(peakChunkMs),
    'chunkBudgetMs': _r(chunkBudgetMs),
    'underruns': underruns,
    'overflows': overflows,
    'startDelayMs': startDelayMs.round(),
  };

  static double _r(double v) => (v * 100).roundToDouble() / 100;
}
