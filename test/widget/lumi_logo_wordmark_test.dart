import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumi/shared/constants/lumi_colors.dart';
import 'package:lumi/shared/widgets/lumi_logo_wordmark.dart';

void main() {
  testWidgets('LumiLogoWordmark renders Dancing Script wordmark text', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: Scaffold(
          backgroundColor: LumiColors.base,
          body: Center(child: LumiLogoWordmark(fontSize: 48)),
        ),
      ),
    );

    expect(find.text('Lumi'), findsOneWidget);
  });
}
