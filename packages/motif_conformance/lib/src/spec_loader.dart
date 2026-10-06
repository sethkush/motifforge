import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

/// How trustworthy a block's expectations are.
enum CaseStatus {
  /// Stated in the public Hookpad guide.
  documented,

  /// Seen by a person using Hookpad.
  observed,

  /// Our best guess; must be verified before release.
  assumed,
}

/// One ```conformance block from a spec file.
final class ConformanceBlock {
  ConformanceBlock({
    required this.id,
    required this.kind,
    required this.status,
    required this.source,
    required this.file,
    required this.line,
    required this.shared,
    required this.cases,
  });

  final String id;
  final String kind;
  final CaseStatus status;
  final String source;

  /// Spec file name, e.g. `chords.md`.
  final String file;

  /// 1-based line of the opening fence.
  final int line;

  /// Block-level fields every case inherits (e.g. `key`).
  final Map<String, Object?> shared;

  /// Cases with [shared] already merged in.
  final List<Map<String, Object?>> cases;

  String get area => p.basenameWithoutExtension(file);
}

final _fence = RegExp(r'^```conformance\s*$');

/// Finds `docs/spec` by walking up from [start] (default: current directory).
Directory findSpecDir([Directory? start]) {
  var dir = (start ?? Directory.current).absolute;
  while (true) {
    final candidate = Directory(p.join(dir.path, 'docs', 'spec'));
    if (candidate.existsSync()) return candidate;
    final parent = dir.parent;
    if (parent.path == dir.path) {
      throw StateError('docs/spec not found above ${Directory.current.path}');
    }
    dir = parent;
  }
}

/// Loads every conformance block in [specDir]'s markdown files.
List<ConformanceBlock> loadBlocks([Directory? specDir]) {
  final dir = specDir ?? findSpecDir();
  final files =
      dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.md'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  final blocks = <ConformanceBlock>[];
  final ids = <String>{};
  for (final file in files) {
    for (final block in parseBlocks(
      file.readAsStringSync(),
      p.basename(file.path),
    )) {
      if (!ids.add(block.id)) {
        throw FormatException('Duplicate conformance id ${block.id}');
      }
      blocks.add(block);
    }
  }
  return blocks;
}

/// Extracts the conformance blocks from one markdown document.
List<ConformanceBlock> parseBlocks(String markdown, String fileName) {
  final lines = markdown.split('\n');
  final blocks = <ConformanceBlock>[];
  for (var i = 0; i < lines.length; i++) {
    if (!_fence.hasMatch(lines[i])) continue;
    final start = i;
    final body = <String>[];
    for (i++; i < lines.length && lines[i].trim() != '```'; i++) {
      body.add(lines[i]);
    }
    final where = '$fileName:${start + 1}';
    final yaml = loadYaml(body.join('\n'));
    if (yaml is! YamlMap) throw FormatException('Block is not a map', where);
    final data = _plain(yaml) as Map<String, Object?>;

    String required(String field) {
      final value = data[field];
      if (value is! String || value.isEmpty) {
        throw FormatException('Missing "$field"', where);
      }
      return value;
    }

    final statusText = required('status');
    final status = CaseStatus.values.firstWhere(
      (s) => s.name == statusText,
      orElse: () => throw FormatException('Bad status "$statusText"', where),
    );
    final rawCases = data['cases'];
    if (rawCases is! List || rawCases.isEmpty) {
      throw FormatException('Missing "cases"', where);
    }
    final shared = Map<String, Object?>.of(data)
      ..removeWhere(
        (k, _) => const {'id', 'kind', 'status', 'source', 'cases'}.contains(k),
      );
    blocks.add(
      ConformanceBlock(
        id: required('id'),
        kind: required('kind'),
        status: status,
        source: required('source'),
        file: fileName,
        line: start + 1,
        shared: shared,
        cases: [
          for (final c in rawCases)
            if (c is Map<String, Object?>)
              {...shared, ...c}
            else
              throw FormatException('Case is not a map', where),
        ],
      ),
    );
  }
  return blocks;
}

/// Converts YAML nodes into plain Dart maps/lists.
Object? _plain(Object? node) => switch (node) {
  YamlMap() => {
    for (final e in node.entries) e.key.toString(): _plain(e.value),
  },
  YamlList() => [for (final v in node) _plain(v)],
  _ => node,
};
