import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumi/shared/constants/lumi_colors.dart';

void main() {
  group('LumiColors', () {
    test('base color is correct', () {
      expect(LumiColors.base, const Color(0xFFF5F5F7));
    });

    test('surface color is correct', () {
      expect(LumiColors.surface, const Color(0xFFFFFFFF));
    });

    test('warning color is orange-red, not pure red', () {
      expect(LumiColors.warning, const Color(0xFFFF6B35));
      expect(LumiColors.warning, isNot(const Color(0xFFFF0000)));
    });
  });
}
