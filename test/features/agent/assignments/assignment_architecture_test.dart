import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final root = Directory('lib/features/agent/assignments');

  test('every assignment feature file stays at or below 250 lines', () {
    final files = root
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));

    for (final file in files) {
      final lines = file.readAsLinesSync().length;
      expect(
        lines,
        lessThanOrEqualTo(250),
        reason: '${file.path} has $lines lines; split it by responsibility.',
      );
    }
  });

  test('widgets and state never bypass the feature repository', () {
    final files = root
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .where((file) => !file.path.contains('/data/'));

    for (final file in files) {
      final source = file.readAsStringSync();
      expect(source, isNot(contains("package:dio")), reason: file.path);
      expect(source, isNot(contains('ApiService')), reason: file.path);
      expect(source, isNot(contains('/api/agent/')), reason: file.path);
    }
  });

  test('feature widgets use design tokens instead of hardcoded colours', () {
    final widgets = Directory('${root.path}/widgets')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));

    for (final file in widgets) {
      final source = file.readAsStringSync();
      expect(source, isNot(contains('Color(0x')), reason: file.path);
      expect(
        source.replaceAll('AppColors.', ''),
        isNot(contains('Colors.')),
        reason: file.path,
      );
    }
  });
}
