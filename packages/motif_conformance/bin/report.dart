import 'dart:io';

import 'package:motif_conformance/motif_conformance.dart';

/// Prints a parity summary: cases per spec file, by outcome and by status.
///
///     dart run motif_conformance:report
void main() {
  final blocks = loadBlocks();
  final byArea = <String, Map<Outcome, int>>{};
  final byStatus = <CaseStatus, Map<Outcome, int>>{};
  final failures = <String>[];

  for (final block in blocks) {
    for (final c in block.cases) {
      final result = runCase(block, c);
      (byArea[block.area] ??= {}).update(
        result.outcome,
        (n) => n + 1,
        ifAbsent: () => 1,
      );
      (byStatus[block.status] ??= {}).update(
        result.outcome,
        (n) => n + 1,
        ifAbsent: () => 1,
      );
      if (result.outcome == Outcome.fail) {
        failures.add(
          '${block.file}:${block.line} ${block.id}: ${result.message}',
        );
      }
    }
  }

  String row(String label, Map<Outcome, int> m) {
    final pass = m[Outcome.pass] ?? 0;
    final fail = m[Outcome.fail] ?? 0;
    final pending = m[Outcome.pending] ?? 0;
    final total = pass + fail + pending;
    final pct = total == 0 ? 0 : (100 * pass / total).round();
    return '${label.padRight(12)} ${'$total'.padLeft(5)} ${'$pass'.padLeft(5)} '
        '${'$fail'.padLeft(5)} ${'$pending'.padLeft(8)} ${'$pct%'.padLeft(6)}';
  }

  final header = '${'spec'.padRight(12)} total  pass  fail  pending  parity';
  stdout.writeln(header);
  final totals = <Outcome, int>{};
  for (final entry
      in (byArea.entries.toList()..sort((a, b) => a.key.compareTo(b.key)))) {
    stdout.writeln(row(entry.key, entry.value));
    entry.value.forEach((k, v) => totals[k] = (totals[k] ?? 0) + v);
  }
  stdout.writeln(row('ALL', totals));
  stdout.writeln();
  stdout.writeln('${'status'.padRight(12)} total  pass  fail  pending  parity');
  for (final s in CaseStatus.values) {
    if (byStatus[s] != null) stdout.writeln(row(s.name, byStatus[s]!));
  }
  if (failures.isNotEmpty) {
    stdout.writeln('\nFailures:');
    failures.forEach(stdout.writeln);
    exitCode = 1;
  }
}
