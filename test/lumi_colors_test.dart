import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumi/shared/constants/lumi_colors.dart';

void main() {
  group('LumiColors', () {
    test('base color is warm cream', () {
      expect(LumiColors.base, const Color(0xFFFAF4EE));
    });

    test('surface color is correct', () {
      expect(LumiColors.surface, const Color(0xFFFFFFFF));
    });

    test('primary color is warm orange', () {
      expect(LumiColors.primary, const Color(0xFFF08630));
    });

    test('warning color is deep orange-red, not pure red', () {
      expect(LumiColors.warning, const Color(0xFFE05528));
      expect(LumiColors.warning, isNot(const Color(0xFFFF0000)));
    });
  });
}
