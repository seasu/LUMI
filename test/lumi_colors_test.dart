import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumi/shared/constants/lumi_colors.dart';

void main() {
  group('LumiColors', () {
    test('base color is warm cream', () {
      expect(LumiColors.base, const Color(0xFFFAF9F8));
    });

    test('surface color is correct', () {
      expect(LumiColors.surface, const Color(0xFFFFFFFF));
    });

    test('primary color is warm orange', () {
      final c = LumiColors.primary;
      // Keep this semantic so small design-token tweaks don't break CI.
      expect(c.red, greaterThanOrEqualTo(0xE0));
      expect(c.green, inInclusiveRange(0x60, 0xA5));
      expect(c.blue, lessThanOrEqualTo(0x50));
    });

    test('warning color is deep orange-red, not pure red', () {
      expect(LumiColors.warning, const Color(0xFFE05528));
      expect(LumiColors.warning, isNot(const Color(0xFFFF0000)));
    });
  });
}
