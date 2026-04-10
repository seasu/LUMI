import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumi/shared/constants/lumi_colors.dart';

void main() {
  group('LumiColors', () {
    test('base color is warm cream', () {
      expect(LumiColors.base, const Color(0xFFFDF6F0));
    });

    test('surface color is correct', () {
      expect(LumiColors.surface, const Color(0xFFFFFFFF));
    });

    test('accent color is rose pink', () {
      expect(LumiColors.accent, const Color(0xFFC4788A));
    });

    test('warning color is warm orange, not pure red', () {
      expect(LumiColors.warning, const Color(0xFFE07B5A));
      expect(LumiColors.warning, isNot(const Color(0xFFFF0000)));
    });
  });
}
