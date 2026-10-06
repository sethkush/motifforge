import 'package:motif_conformance/motif_conformance.dart';
import 'package:test/test.dart';

/// One test per conformance case in docs/spec. Pending kinds are skipped so
/// they show up in the run without failing it.
void main() {
  final blocks = loadBlocks();

  test('specs contain conformance cases', () {
    expect(blocks, isNotEmpty);
  });

  for (final block in blocks) {
    group('${block.file} ${block.id} [${block.status.name}]', () {
      final pending = runners.containsKey(block.kind)
          ? null
          : pendingKinds[block.kind] ?? 'no runner for "${block.kind}"';
      for (var i = 0; i < block.cases.length; i++) {
        final c = block.cases[i];
        test('case ${i + 1}', skip: pending, () {
          final result = runCase(block, c);
          if (result.outcome == Outcome.fail) {
            fail('${block.file}:${block.line} $c\n${result.message}');
          }
        });
      }
    });
  }
}
