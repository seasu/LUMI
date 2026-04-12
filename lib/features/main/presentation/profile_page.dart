import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/constants/lumi_colors.dart';
import '../../../shared/constants/lumi_spacing.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../user/data/user_repository.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).valueOrNull;

    return Scaffold(
      backgroundColor: LumiColors.base,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: LumiSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: LumiSpacing.lg),
              const Text(
                '個人檔案',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: LumiColors.text,
                ),
              ),
              const SizedBox(height: LumiSpacing.lg),
              if (profile != null) ...[
                _ProfileRow(
                  icon: Icons.person_outline,
                  label: profile.displayName,
                ),
                const SizedBox(height: LumiSpacing.sm),
                _ProfileRow(
                  icon: Icons.email_outlined,
                  label: profile.email,
                ),
                const SizedBox(height: LumiSpacing.sm),
                _ProfileRow(
                  icon: Icons.photo_library_outlined,
                  label: '已分析 ${profile.analyzedCount} / ${profile.freeQuota} 件',
                ),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => signOut(ref),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: LumiColors.subtext,
                    side: const BorderSide(color: LumiColors.subtext),
                    padding: const EdgeInsets.symmetric(
                        vertical: LumiSpacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: const Text('登出'),
                ),
              ),
              const SizedBox(height: LumiSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(LumiSpacing.md),
      decoration: BoxDecoration(
        color: LumiColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: LumiColors.subtext),
          const SizedBox(width: LumiSpacing.md),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                color: LumiColors.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
