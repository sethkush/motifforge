import 'package:audio_spike/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support.dart';

/// Drives the spike app through its UI like a user would: start playback,
/// tap a note, change settings, stop, run the benchmark, copy results.
/// Screenshots at each step; audio markers for the host-side recording.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('spike UI end to end', (tester) async {
    await tester.pumpWidget(const SpikeApp());
    await tester.pump();
    expect(find.text('Stopped'), findsOneWidget);
    await screenshot(binding, tester, '01-launch');

    // Start playback.
    mark('ui-start');
    await tester.tap(find.text('Start'));
    await tester.pump();
    expect(find.text('Playing'), findsOneWidget);
    await waitReal(tester, const Duration(seconds: 4));
    await tester.pump();
    expect(find.text('Average render load'), findsOneWidget);
    expect(find.text('Device underruns (buffer ran dry)'), findsOneWidget);
    await screenshot(binding, tester, '02-playing');

    // Tap a note while playing (latency check button).
    mark('ui-tap-note');
    await tester.tap(find.text('Tap note (latency check)'));
    await waitReal(tester, const Duration(milliseconds: 500));

    // Turn the band off: only tapped notes should sound.
    await tester.tap(find.text('Band pattern'));
    await tester.pump();
    mark('ui-band-off');
    await waitReal(tester, const Duration(seconds: 1));
    await tester.tap(find.text('Tap note (latency check)'));
    mark('ui-tap-note-solo');
    await waitReal(tester, const Duration(seconds: 1));
    await tester.tap(find.text('Band pattern'));
    mark('ui-band-on');
    await waitReal(tester, const Duration(seconds: 2));

    // Stop.
    await tester.tap(find.text('Stop'));
    await tester.pump();
    mark('ui-stop');
    expect(find.text('Stopped'), findsOneWidget);
    await screenshot(binding, tester, '03-stopped');

    // Settings that only apply when stopped are enabled again.
    final fxSwitch = tester.widget<SwitchListTile>(
      find.widgetWithText(
        SwitchListTile,
        'Reverb + chorus (applies on restart)',
      ),
    );
    expect(fxSwitch.onChanged, isNotNull);

    // CPU benchmark through the button.
    await tester.tap(find.text('Run CPU benchmark'));
    await tester.pump();
    for (
      var i = 0;
      i < 240 && find.text('Run CPU benchmark').evaluate().isEmpty;
      i++
    ) {
      await waitReal(tester, const Duration(milliseconds: 500));
      await tester.pump();
    }
    expect(find.text('Run CPU benchmark'), findsOneWidget);
    // The list is lazy: scroll to the last benchmark line to prove all 8 ran.
    await tester.scrollUntilVisible(
      find.textContaining('band + 64 stress voices (no fx)'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    await screenshot(binding, tester, '04-benchmark');

    // Copy results (scroll back up to the buttons first).
    await tester.scrollUntilVisible(
      find.text('Copy results'),
      -300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Copy results'));
    await tester.pump();
    expect(find.text('Results copied'), findsOneWidget);
  }, timeout: const Timeout(Duration(minutes: 10)));
}
