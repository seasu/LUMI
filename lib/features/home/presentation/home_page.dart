import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/constants/lumi_colors.dart';
import '../../../shared/constants/lumi_spacing.dart';
import '../../../shared/constants/lumi_type_scale.dart';
import '../../auth/presentation/providers/auth_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(firebaseAuthProvider).currentUser;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: LumiColors.base,
      appBar: AppBar(
        backgroundColor: LumiColors.base,
        elevation: 0,
        title: const Text(
          'Lumi',
          style: TextStyle(
            fontSize: LumiTypeScale.headlineMd,
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
              Text(
                l10n.homeEmpty,
                style: const TextStyle(
                  fontSize: LumiTypeScale.titleLg,
                  fontWeight: FontWeight.w500,
                  color: LumiColors.text,
                ),
              ),
              const SizedBox(height: LumiSpacing.sm),
              Text(
                l10n.homeEmptyHint(user?.displayName ?? ''),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: LumiTypeScale.body,
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
        label: Text(l10n.homeFab),
        icon: const Icon(Icons.camera_alt_outlined),
      ),
    );
  }
}
