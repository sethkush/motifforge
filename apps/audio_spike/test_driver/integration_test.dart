import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

/// Host side of `flutter drive`: saves screenshots taken through the
/// integration-test binding (mobile, web) to build/screenshots/, and the
/// test's report data to build/integration_response_data.json.
Future<void> main() => integrationDriver(
  onScreenshot: (name, bytes, [args]) async {
    final file = File('build/screenshots/$name.png');
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(bytes);
    return true;
  },
);
