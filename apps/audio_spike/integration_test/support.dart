import 'dart:convert';
import 'dart:ui' as ui;

import 'package:audio_spike/main.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'write_file_stub.dart' if (dart.library.io) 'write_file_io.dart';

/// Where desktop runs write screenshots (absolute path from the host script).
const shotDir = String.fromEnvironment(
  'SHOT_DIR',
  defaultValue: 'build/screenshots',
);

bool get _usesBindingScreenshots =>
    kIsWeb ||
    defaultTargetPlatform == TargetPlatform.android ||
    defaultTargetPlatform == TargetPlatform.iOS;

bool _surfaceConverted = false;

/// Captures the app as `<name>.png`. Mobile and web go through the
/// integration-test binding (the driver saves the file on the host); desktop
/// renders the app's root boundary directly.
Future<void> screenshot(
  IntegrationTestWidgetsFlutterBinding binding,
  WidgetTester tester,
  String name,
) async {
  await tester.pump();
  if (_usesBindingScreenshots) {
    if (!kIsWeb && !_surfaceConverted) {
      await binding.convertFlutterSurfaceToImage();
      _surfaceConverted = true;
      await tester.pump();
    }
    await binding.takeScreenshot(name);
    mark('screenshot', {'name': name});
    return;
  }
  final boundary =
      screenshotKey.currentContext!.findRenderObject()!
          as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    writeBytes('$shotDir/$name.png', bytes!.buffer.asUint8List());
  });
  mark('screenshot', {'name': name});
}

/// Prints a timestamped marker the host scripts use to line up the audio
/// recording and the log: `SPIKE_MARK {"event": ..., "epochMs": ...}`.
void mark(String event, [Map<String, Object?> data = const {}]) {
  // ignore: avoid_print
  print(
    'SPIKE_MARK ${jsonEncode({'event': event, 'epochMs': DateTime.now().millisecondsSinceEpoch, ...data})}',
  );
}

/// Real-time wait inside a widget test (the clock isn't faked in
/// integration tests, but runAsync keeps timers and I/O honest).
Future<void> waitReal(WidgetTester tester, Duration d) =>
    tester.runAsync(() => Future<void>.delayed(d));
