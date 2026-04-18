import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumi/shared/constants/lumi_colors.dart';

void main() {
  group('LumiColors', () {
    test('base matches DESIGN.md Gallery Bone (#faf9f8)', () {
      expect(LumiColors.base, const Color(0xFFFAF9F8));
    });

    test('surface is pure white for cards/sheets', () {
      expect(LumiColors.surface, const Color(0xFFFFFFFF));
    });

    test('primary is DESIGN.md liquid gold anchor (#904d00)', () {
      expect(LumiColors.primary, const Color(0xFF904D00));
    });

    test('text/on_surface matches DESIGN.md (#1a1c1c)', () {
      expect(LumiColors.text, const Color(0xFF1A1C1C));
    });

    test('warning is warm orange-red, not pure red', () {
      expect(LumiColors.warning, isNot(const Color(0xFFFF0000)));
      expect(LumiColors.warning.red, greaterThan(LumiColors.warning.blue));
    });
  });
}
