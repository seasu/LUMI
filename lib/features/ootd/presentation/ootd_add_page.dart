import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/constants/lumi_colors.dart';
import '../../../shared/constants/lumi_radii.dart';
import '../../../shared/constants/lumi_spacing.dart';
import '../../../shared/constants/lumi_type_scale.dart';
import '../domain/ootd_state.dart';
import 'ootd_share_page.dart';
import 'providers/ootd_provider.dart';

class OotdAddPage extends ConsumerStatefulWidget {
  const OotdAddPage({super.key, this.source = ImageSource.camera});

  final ImageSource source;

  @override
  ConsumerState<OotdAddPage> createState() => _OotdAddPageState();
}

class _OotdAddPageState extends ConsumerState<OotdAddPage> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ootdAddProvider.notifier).reset();
      ref.read(ootdAddProvider.notifier).pickPhoto(source: widget.source);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ootdAddProvider);

    ref.listen<OotdAddState>(ootdAddProvider, (_, next) {
      // Photo picked → auto-save immediately, no intermediate edit page
      if (next is OotdAddEditing) {
        ref.read(ootdAddProvider.notifier).save();
      }

      // Save done → push share page directly (slide-from-bottom)
      if (next is OotdAddResult && !_navigated) {
        _navigated = true;
        final bytes = next.photoBytes;
        final date = next.item.date;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final router = GoRouter.of(context);
          Navigator.of(context)
              .push<void>(
            PageRouteBuilder<void>(
              pageBuilder: (ctx, _, __) => OotdSharePage(
                photoBytes: bytes,
                caption: '',
                date: date,
              ),
              transitionsBuilder: (_, anim, __, child) => SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
                ),
                child: child,
              ),
              transitionDuration: const Duration(milliseconds: 360),
            ),
          )
              .then((_) {
            if (!mounted) return;
            ref.read(ootdAddProvider.notifier).reset();
            router.go('/home/outfits');
          });
        });
      }
    });

    return PopScope(
      canPop: state is! OotdAddSaving,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) ref.read(ootdAddProvider.notifier).reset();
      },
      child: switch (state) {
        // All in-progress states show minimal dark loading screen
        OotdAddIdle() ||
        OotdAddEditing() ||
        OotdAddSaving() ||
        OotdAddResult() =>
          _PickingView(
            onClose: () {
              ref.read(ootdAddProvider.notifier).reset();
              context.pop();
            },
          ),
        OotdAddError(:final message) => _ErrorView(
            message: message,
            onBack: () {
              ref.read(ootdAddProvider.notifier).reset();
              context.pop();
            },
          ),
      },
    );
  }
}

// ── 選取 / 儲存中（短暫過渡畫面）────────────────────────────────────────────────

class _PickingView extends StatelessWidget {
  const _PickingView({required this.onClose});
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LumiColors.overlayDark,
      body: SafeArea(
        child: Stack(
          children: [
            const Center(
              child: CircularProgressIndicator(color: LumiColors.onPrimary),
            ),
            Positioned(
              top: LumiSpacing.md,
              left: LumiSpacing.xs,
              child: IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close,
                    color: LumiColors.onPrimary, size: 28),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 錯誤 ──────────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onBack});
  final String message;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LumiColors.base,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(LumiSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(LumiSpacing.md),
                decoration: BoxDecoration(
                  color: LumiColors.warning.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(LumiRadii.lg),
                ),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: LumiTypeScale.labelMd,
                    color: LumiColors.warning,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: LumiSpacing.lg),
              _PrimaryButton(label: '返回', onTap: onBack),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shared button ─────────────────────────────────────────────────────────────

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: LumiColors.buttonGradient,
          borderRadius: BorderRadius.circular(LumiRadii.pill),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: LumiTypeScale.titleSm,
              fontWeight: FontWeight.w600,
              color: LumiColors.onPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
