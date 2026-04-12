import 'package:flutter/material.dart';
import '../../../shared/constants/lumi_colors.dart';

class OutfitPage extends StatelessWidget {
  const OutfitPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: LumiColors.base,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.style_outlined, size: 56, color: LumiColors.subtext),
              SizedBox(height: 16),
              Text(
                '我的穿搭',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: LumiColors.text,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '即將推出',
                style: TextStyle(fontSize: 15, color: LumiColors.subtext),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
