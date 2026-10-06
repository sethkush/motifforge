import 'package:motif_conformance/motif_conformance.dart';
import 'package:test/test.dart';

void main() {
  test('parses blocks and merges shared fields into cases', () {
    const md = '''
# Title

```conformance
id: x.one
kind: chord
status: assumed
source: test
key: C major
cases:
  - {spec: {degree: 1}, symbol: C}
  - {key: A minor, spec: {degree: 1}, symbol: Am}
```

```dart
not a conformance block
```
''';
    final blocks = parseBlocks(md, 'x.md');
    expect(blocks, hasLength(1));
    final b = blocks.single;
    expect(b.id, 'x.one');
    expect(b.status, CaseStatus.assumed);
    expect(b.line, 3);
    expect(b.cases[0]['key'], 'C major');
    expect(b.cases[1]['key'], 'A minor');
    for (final c in b.cases) {
      expect(runCase(b, c).outcome, Outcome.pass);
    }
  });

  test('reports mismatches', () {
    const md = '''
```conformance
id: x.bad
kind: chord
status: assumed
source: test
cases:
  - {key: C major, spec: {degree: 2}, symbol: D}
```
''';
    final b = parseBlocks(md, 'x.md').single;
    final result = runCase(b, b.cases.single);
    expect(result.outcome, Outcome.fail);
    expect(result.message, contains('expected "D", got "Dm"'));
  });

  test('rejects blocks without a status', () {
    const md = '''
```conformance
id: x.nostatus
kind: chord
source: test
cases: [{}]
```
''';
    expect(() => parseBlocks(md, 'x.md'), throwsFormatException);
  });
}
