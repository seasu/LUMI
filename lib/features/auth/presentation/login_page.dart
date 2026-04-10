import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/constants/lumi_colors.dart';
import '../../../shared/constants/lumi_spacing.dart';
import 'providers/auth_provider.dart';

class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(signInLoadingProvider);

    return Scaffold(
      backgroundColor: LumiColors.base,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: LumiSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                _buildLogo(),
                const SizedBox(height: LumiSpacing.lg),
                _buildTagline(context),
                const Spacer(),
                _buildSignInButton(context, ref, isLoading),
                const SizedBox(height: LumiSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return const Text(
      'Lumi',
      style: TextStyle(
        fontSize: 48,
        fontWeight: FontWeight.w600,
        color: LumiColors.text,
        letterSpacing: -1.5,
      ),
    );
  }

  Widget _buildTagline(BuildContext context) {
    return const Text(
      'Light up your wardrobe\nwith Google Photos.',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w400,
        color: LumiColors.subtext,
        height: 1.5,
      ),
    );
  }

  Widget _buildSignInButton(
    BuildContext context,
    WidgetRef ref,
    bool isLoading,
  ) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: isLoading
            ? null
            : () async {
                try {
                  await signInWithGoogle(ref);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          e.toString().replaceFirst('Exception: ', ''),
                        ),
                        backgroundColor: const Color(0xFFFF6B35),
                      ),
                    );
                  }
                }
              },
        style: FilledButton.styleFrom(
          backgroundColor: LumiColors.text,
          foregroundColor: LumiColors.surface,
          padding: const EdgeInsets.symmetric(vertical: LumiSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: LumiColors.surface,
                ),
              )
            : const Text(
                'Continue with Google',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
      ),
    );
  }
}
