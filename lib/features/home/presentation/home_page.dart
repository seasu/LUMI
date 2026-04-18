import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../shared/constants/lumi_colors.dart';
import '../../../shared/constants/lumi_spacing.dart';
import '../../auth/presentation/providers/auth_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(firebaseAuthProvider).currentUser;

    return Scaffold(
      backgroundColor: LumiColors.base,
      appBar: AppBar(
        backgroundColor: LumiColors.base,
        elevation: 0,
        title: const Text(
          'Lumi',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: LumiColors.text,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => signOut(ref),
            icon: const Icon(Icons.logout, color: LumiColors.subtext),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(LumiSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '衣櫥是空的',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  color: LumiColors.text,
                ),
              ),
              const SizedBox(height: LumiSpacing.sm),
              Text(
                '歡迎 ${user?.displayName ?? ''}，點下方按鈕開始拍照入庫',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: LumiColors.subtext,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/snap'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        label: const Text('Lumi Snap'),
        icon: const Icon(Icons.camera_alt_outlined),
      ),
    );
  }
}
