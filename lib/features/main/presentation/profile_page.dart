import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/constants/app_version.dart';
import '../../../shared/constants/lumi_colors.dart';
import '../../../shared/constants/lumi_radii.dart';
import '../../../shared/constants/lumi_spacing.dart';
import '../../../shared/constants/lumi_type_scale.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../debug/debug_log_page.dart';
import '../../purchase/presentation/widgets/paywall_sheet.dart';
import '../../../core/providers/locale_provider.dart';
import '../../user/data/user_profile.dart';
import '../../user/data/user_repository.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: LumiColors.base,
      body: SafeArea(
        child: profileAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: LumiColors.primary),
          ),
          error: (_, __) => Center(
            child: Text(
              AppLocalizations.of(context).error,
              style: const TextStyle(color: LumiColors.subtext),
            ),
          ),
          data: (profile) => profile == null
              ? const Center(
                  child: CircularProgressIndicator(color: LumiColors.primary),
                )
              : _ProfileContent(profile: profile),
        ),
      ),
    );
  }
}

class _ProfileContent extends ConsumerWidget {
  const _ProfileContent({required this.profile});
  final UserProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        LumiSpacing.lg,
        LumiSpacing.md,
        LumiSpacing.md,
        LumiSpacing.lg,
      ),
      children: [
        Text(
          AppLocalizations.of(context).profileTitle,
          style: const TextStyle(
            fontSize: LumiTypeScale.headlineMd,
            fontWeight: FontWeight.w700,
            color: LumiColors.text,
          ),
        ),
        const SizedBox(height: LumiSpacing.lg),
        Center(
          child: CircleAvatar(
            radius: 48,
            backgroundColor: LumiColors.glow.withValues(alpha: 0.3),
            backgroundImage: profile.photoUrl != null
                ? NetworkImage(profile.photoUrl!)
                : null,
            child: profile.photoUrl == null
                ? const Icon(Icons.person, size: 48, color: LumiColors.subtext)
                : null,
          ),
        ),
        const SizedBox(height: LumiSpacing.md),
        Center(
          child: Text(
            profile.displayName.isEmpty ? profile.email : profile.displayName,
            style: const TextStyle(
              fontSize: LumiTypeScale.titleLg,
              fontWeight: FontWeight.w600,
              color: LumiColors.text,
            ),
          ),
        ),
        const SizedBox(height: LumiSpacing.lg),
        const _VersionRow(),
        const SizedBox(height: LumiSpacing.xs),
        _InfoRow(label: 'UID', value: profile.uid),
        const SizedBox(height: LumiSpacing.lg),
        _QuotaCard(profile: profile),
        const SizedBox(height: LumiSpacing.lg),
        Text(
          AppLocalizations.of(context).profileMeasurements,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: LumiTypeScale.body,
            fontWeight: FontWeight.w500,
            color: LumiColors.subtext,
          ),
        ),
        const SizedBox(height: LumiSpacing.md),
        _MeasurementsGrid(profile: profile),
        const SizedBox(height: LumiSpacing.xl),
        OutlinedButton(
          onPressed: () => signOut(ref),
          style: OutlinedButton.styleFrom(
            foregroundColor: LumiColors.subtext,
            side: BorderSide(color: LumiColors.subtext.withValues(alpha: 0.55)),
            padding: const EdgeInsets.symmetric(vertical: LumiSpacing.md),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(LumiRadii.pill),
            ),
          ),
          child: Text(AppLocalizations.of(context).profileSignOut),
        ),
        const SizedBox(height: LumiSpacing.sm),
        _LanguageSelector(),
        const SizedBox(height: LumiSpacing.sm),
        TextButton(
          onPressed: () => _showDeleteAccountDialog(context, ref),
          style: TextButton.styleFrom(
            foregroundColor: LumiColors.warning,
            padding: const EdgeInsets.symmetric(vertical: LumiSpacing.md),
          ),
          child: Text(
            AppLocalizations.of(context).profileDeleteAccount,
            style: const TextStyle(fontSize: LumiTypeScale.body),
          ),
        ),
        const SizedBox(height: LumiSpacing.lg),
      ],
    );
  }

  Future<void> _showDeleteAccountDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const _DeleteAccountDialog(),
    );
    if (confirmed == true && context.mounted) {
      await _doDeleteAccount(context, ref);
    }
  }

  Future<void> _doDeleteAccount(BuildContext context, WidgetRef ref) async {
    // Read all providers before any await.
    // On iOS, signOut() fires authStateChanges synchronously, which triggers
    // GoRouter to navigate away and may dispose this widget mid-execution.
    // Pre-reading prevents "ref used after dispose" crashes.
    final navigator = Navigator.of(context, rootNavigator: true);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _DeletingDialog(),
    );

    try {
      await deleteAccount(ref); // deletes Firestore doc + Firebase Auth user

      // Pop the progress dialog BEFORE signOut.
      // signOut triggers GoRouter navigation synchronously on iOS — if the
      // dialog is still present it ends up on an orphaned stack → black screen.
      navigator.pop();

      await signOut(ref); // clears local session → GoRouter → login page
    } catch (e) {
      navigator.pop(); // dismiss progress dialog on error
      messenger.showSnackBar(
        SnackBar(
          content: Text('${l10n.profileDeleteError}\n$e'),
          backgroundColor: LumiColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

// ── Delete account dialogs ────────────────────────────────────────────────────

class _DeleteAccountDialog extends StatelessWidget {
  const _DeleteAccountDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: LumiColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(LumiRadii.xl),
      ),
      child: Padding(
        padding: const EdgeInsets.all(LumiSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: LumiColors.warning.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_forever_outlined,
                color: LumiColors.warning,
                size: 28,
              ),
            ),
            const SizedBox(height: LumiSpacing.md),
            Text(
              AppLocalizations.of(context).profileDeleteConfirmTitle,
              style: const TextStyle(
                fontSize: LumiTypeScale.titleSm,
                fontWeight: FontWeight.w700,
                color: LumiColors.text,
              ),
            ),
            const SizedBox(height: LumiSpacing.sm),
            Text(
              AppLocalizations.of(context).profileDeleteConfirmBody,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: LumiTypeScale.labelMd,
                color: LumiColors.subtext,
                height: 1.5,
              ),
            ),
            const SizedBox(height: LumiSpacing.lg),
            GestureDetector(
              onTap: () => Navigator.of(context).pop(true),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: LumiSpacing.md),
                decoration: BoxDecoration(
                  color: LumiColors.warning,
                  borderRadius: BorderRadius.circular(LumiRadii.pill),
                ),
                child: Text(
                  AppLocalizations.of(context).profileDeletePermanentButton,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: LumiTypeScale.body,
                    fontWeight: FontWeight.w600,
                    color: LumiColors.onPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: LumiSpacing.xs),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                AppLocalizations.of(context).cancel,
                style: const TextStyle(
                  fontSize: LumiTypeScale.body,
                  color: LumiColors.subtext,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeletingDialog extends StatelessWidget {
  const _DeletingDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: LumiColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(LumiRadii.xl),
      ),
      child: Padding(
        padding: const EdgeInsets.all(LumiSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: LumiColors.warning),
            const SizedBox(height: LumiSpacing.md),
            Builder(builder: (context) => Text(
              AppLocalizations.of(context).profileDeleting,
              style: const TextStyle(
                fontSize: LumiTypeScale.body,
                color: LumiColors.subtext,
              ),
            )),
          ],
        ),
      ),
    );
  }
}

// ── Quota progress card ────────────────────────────────────────────────────────

class _QuotaCard extends StatelessWidget {
  const _QuotaCard({required this.profile});
  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final isPro = profile.plan == 'pro';
    final used = profile.analyzedCount;
    final quota = profile.freeQuota;
    final remaining = profile.remainingQuota;
    final progress = isPro ? 1.0 : (quota > 0 ? (used / quota).clamp(0.0, 1.0) : 0.0);
    final isNearLimit = !isPro && remaining <= 5;

    return Container(
      padding: const EdgeInsets.all(LumiSpacing.md),
      decoration: BoxDecoration(
        color: LumiColors.surface,
        borderRadius: BorderRadius.circular(LumiRadii.lg),
        border: isNearLimit
            ? Border.all(color: LumiColors.warning.withValues(alpha: 0.35))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              const Icon(Icons.auto_awesome_outlined,
                  size: 16, color: LumiColors.primary),
              const SizedBox(width: LumiSpacing.sm),
              Text(
                AppLocalizations.of(context).quotaTitle,
                style: const TextStyle(
                  fontSize: LumiTypeScale.labelMd,
                  fontWeight: FontWeight.w600,
                  color: LumiColors.text,
                ),
              ),
              const Spacer(),
              if (isPro)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: LumiSpacing.sm, vertical: 2),
                  decoration: BoxDecoration(
                    gradient: LumiColors.buttonGradient,
                    borderRadius: BorderRadius.circular(LumiRadii.pill),
                  ),
                  child: const Text(
                    'Pro',
                    style: TextStyle(
                      fontSize: LumiTypeScale.labelSm,
                      fontWeight: FontWeight.w700,
                      color: LumiColors.onPrimary,
                    ),
                  ),
                )
              else
                Text(
                  AppLocalizations.of(context).quotaUsed(used, quota),
                  style: TextStyle(
                    fontSize: LumiTypeScale.labelMd,
                    fontWeight: FontWeight.w600,
                    color: isNearLimit ? LumiColors.warning : LumiColors.subtext,
                  ),
                ),
            ],
          ),
          const SizedBox(height: LumiSpacing.sm),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(LumiRadii.pill),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: LumiColors.baseAlt,
              valueColor: AlwaysStoppedAnimation<Color>(
                isNearLimit ? LumiColors.warning : LumiColors.primary,
              ),
            ),
          ),
          const SizedBox(height: LumiSpacing.sm),

          // Sub-text
          if (isPro)
            Text(
              AppLocalizations.of(context).quotaProActive,
              style: const TextStyle(
                fontSize: LumiTypeScale.labelMd,
                color: LumiColors.subtext,
              ),
            )
          else
            Text(
              AppLocalizations.of(context).quotaRemaining(remaining),
              style: TextStyle(
                fontSize: LumiTypeScale.labelMd,
                color: isNearLimit ? LumiColors.warning : LumiColors.subtext,
              ),
            ),

          // Upgrade button (free plan only)
          if (!isPro) ...[
            const SizedBox(height: LumiSpacing.md),
            GestureDetector(
              onTap: () => showPaywallSheet(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: LumiSpacing.sm),
                decoration: BoxDecoration(
                  gradient: LumiColors.buttonGradient,
                  borderRadius: BorderRadius.circular(LumiRadii.pill),
                ),
                child: Text(
                  AppLocalizations.of(context).quotaUpgradeHint,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: LumiTypeScale.labelMd,
                    fontWeight: FontWeight.w600,
                    color: LumiColors.onPrimary,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.symmetric(
        horizontal: LumiSpacing.md,
        vertical: LumiSpacing.sm,
      ),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: LumiColors.surface,
        borderRadius: BorderRadius.circular(LumiRadii.lg),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: LumiTypeScale.labelMd,
              color: LumiColors.subtext,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: LumiSpacing.sm),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: LumiTypeScale.labelMd,
                color: LumiColors.text,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Version row with 5-tap debug unlock ──────────────────────────────────────

class _VersionRow extends StatefulWidget {
  const _VersionRow();

  @override
  State<_VersionRow> createState() => _VersionRowState();
}

class _VersionRowState extends State<_VersionRow> {
  int _taps = 0;

  void _onTap() {
    setState(() => _taps++);
    if (_taps >= 5) {
      setState(() => _taps = 0);
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const DebugLogPage()),
      );
    } else {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).profileDebugHint(5 - _taps)),
            duration: const Duration(milliseconds: 800),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      behavior: HitTestBehavior.opaque,
      child: Builder(
        builder: (context) => _InfoRow(
          label: AppLocalizations.of(context).profileVersion,
          value: appVersionLabel,
        ),
      ),
    );
  }
}

// ── Measurements 2-column grid ────────────────────────────────────────────────

class _MeasurementsGrid extends StatelessWidget {
  const _MeasurementsGrid({required this.profile});
  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final items = _measurementItems(profile, AppLocalizations.of(context));
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: LumiSpacing.sm,
        mainAxisSpacing: LumiSpacing.sm,
        childAspectRatio: 2.4,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) => _MeasurementCard(item: items[i]),
    );
  }

  List<_MeasurementItem> _measurementItems(UserProfile p, AppLocalizations l10n) => [
        _MeasurementItem(
          icon: Icons.accessibility_new_outlined,
          label: l10n.measureHeight,
          field: 'heightCm',
          value: p.heightCm != null
              ? '${p.heightCm!.toStringAsFixed(0)} cm'
              : '—',
          unit: 'cm',
          currentValue: p.heightCm?.toString(),
        ),
        _MeasurementItem(
          icon: Icons.monitor_weight_outlined,
          label: l10n.measureWeight,
          field: 'weightKg',
          value: p.weightKg != null
              ? '${p.weightKg!.toStringAsFixed(0)} kg'
              : '—',
          unit: 'kg',
          currentValue: p.weightKg?.toString(),
        ),
        _MeasurementItem(
          icon: Icons.calendar_today_outlined,
          label: l10n.measureBirthday,
          field: 'birthday',
          value: p.birthday != null ? _formatBirthday(p.birthday!) : '—',
          unit: '',
          currentValue: p.birthday,
          isDate: true,
        ),
        _MeasurementItem(
          icon: Icons.face_outlined,
          label: l10n.measureHead,
          field: 'headCircumferenceCm',
          value: p.headCircumferenceCm != null
              ? '${p.headCircumferenceCm!.toStringAsFixed(0)} cm'
              : '—',
          unit: 'cm',
          currentValue: p.headCircumferenceCm?.toString(),
        ),
        _MeasurementItem(
          icon: Icons.favorite_border,
          label: l10n.measureChest,
          field: 'chestCm',
          value:
              p.chestCm != null ? '${p.chestCm!.toStringAsFixed(0)} cm' : '—',
          unit: 'cm',
          currentValue: p.chestCm?.toString(),
        ),
        _MeasurementItem(
          icon: Icons.straighten_outlined,
          label: l10n.measureWaist,
          field: 'waistCm',
          value:
              p.waistCm != null ? '${p.waistCm!.toStringAsFixed(0)} cm' : '—',
          unit: 'cm',
          currentValue: p.waistCm?.toString(),
        ),
        _MeasurementItem(
          icon: Icons.airline_seat_legroom_normal_outlined,
          label: l10n.measureHips,
          field: 'hipCm',
          value: p.hipCm != null ? '${p.hipCm!.toStringAsFixed(0)} cm' : '—',
          unit: 'cm',
          currentValue: p.hipCm?.toString(),
        ),
        _MeasurementItem(
          icon: Icons.directions_walk_outlined,
          label: l10n.measureInseam,
          field: 'legLengthCm',
          value: p.legLengthCm != null
              ? '${p.legLengthCm!.toStringAsFixed(0)} cm'
              : '—',
          unit: 'cm',
          currentValue: p.legLengthCm?.toString(),
        ),
      ];

  static String _formatBirthday(String iso) {
    final parts = iso.split('-');
    if (parts.length < 3) return iso;
    return '${parts[0]}年${parts[1].padLeft(2, '0')}月${parts[2].padLeft(2, '0')}日';
  }
}

class _MeasurementItem {
  const _MeasurementItem({
    required this.icon,
    required this.label,
    required this.field,
    required this.value,
    required this.unit,
    this.currentValue,
    this.isDate = false,
  });

  final IconData icon;
  final String label;
  final String field;
  final String value;
  final String unit;
  final String? currentValue;
  final bool isDate;
}

class _MeasurementCard extends ConsumerWidget {
  const _MeasurementCard({required this.item});
  final _MeasurementItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _showEditDialog(context, ref),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: LumiSpacing.md,
          vertical: LumiSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: LumiColors.surface,
          borderRadius: BorderRadius.circular(LumiRadii.lg),
        ),
        child: Row(
          children: [
            Icon(item.icon, size: 18, color: LumiColors.subtext),
            const SizedBox(width: LumiSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.label,
                    style: const TextStyle(
                      fontSize: LumiTypeScale.labelSm,
                      color: LumiColors.subtext,
                    ),
                  ),
                  Text(
                    item.value,
                    style: const TextStyle(
                      fontSize: LumiTypeScale.labelMd,
                      fontWeight: FontWeight.w600,
                      color: LumiColors.text,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 16, color: LumiColors.subtext),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditDialog(BuildContext context, WidgetRef ref) async {
    final user = ref.read(userProfileProvider).valueOrNull;
    if (user == null) return;

    await showDialog<void>(
      context: context,
      builder: (_) => _EditMeasurementDialog(
        item: item,
        userId: user.uid,
        onSave: (value) async {
          dynamic parsed;
          if (item.isDate) {
            parsed = value;
          } else {
            parsed = double.tryParse(value);
            if (parsed == null) return;
          }
          await ref
              .read(userRepositoryProvider)
              .updateMeasurement(user.uid, item.field, parsed);
        },
      ),
    );
  }
}

// ── Edit Dialog ───────────────────────────────────────────────────────────────

class _EditMeasurementDialog extends StatefulWidget {
  const _EditMeasurementDialog({
    required this.item,
    required this.userId,
    required this.onSave,
  });

  final _MeasurementItem item;
  final String userId;
  final Future<void> Function(String value) onSave;

  @override
  State<_EditMeasurementDialog> createState() => _EditMeasurementDialogState();
}

class _EditMeasurementDialogState extends State<_EditMeasurementDialog> {
  late final TextEditingController _ctrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.item.currentValue ?? '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final value = _ctrl.text.trim();
    if (value.isEmpty) return;
    setState(() => _saving = true);
    try {
      await widget.onSave(value);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: LumiColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(LumiRadii.xl),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          LumiSpacing.lg,
          LumiSpacing.lg,
          LumiSpacing.lg,
          LumiSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppLocalizations.of(context).itemDetailEditTitle(widget.item.label),
              style: const TextStyle(
                fontSize: LumiTypeScale.titleSm,
                fontWeight: FontWeight.w600,
                color: LumiColors.text,
              ),
            ),
            const SizedBox(height: LumiSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Flexible(
                  child: TextField(
                    controller: _ctrl,
                    textAlign: TextAlign.center,
                    keyboardType: widget.item.isDate
                        ? TextInputType.datetime
                        : const TextInputType.numberWithOptions(decimal: true),
                    // Large display-size for measurement input — intentionally
                    // outside LumiTypeScale as this is a numpad-style UI element.
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w300,
                      color: LumiColors.text,
                    ),
                    decoration: const InputDecoration(border: InputBorder.none),
                  ),
                ),
                if (widget.item.unit.isNotEmpty)
                  Text(
                    ' ${widget.item.unit}',
                    style: const TextStyle(
                      fontSize: LumiTypeScale.titleLg,
                      color: LumiColors.subtext,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: LumiSpacing.lg),
            GestureDetector(
              onTap: _saving ? null : _save,
              child: Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  gradient: _saving ? null : LumiColors.buttonGradient,
                  color: _saving
                      ? LumiColors.primary.withValues(alpha: 0.5)
                      : null,
                  borderRadius: BorderRadius.circular(LumiRadii.pill),
                ),
                child: Center(
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: LumiColors.onPrimary,
                          ),
                        )
                      : Text(
                          AppLocalizations.of(context).save,
                          style: const TextStyle(
                            fontSize: LumiTypeScale.titleSm,
                            fontWeight: FontWeight.w600,
                            color: LumiColors.onPrimary,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: LumiSpacing.xs),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                AppLocalizations.of(context).cancel,
                style: const TextStyle(
                  fontSize: LumiTypeScale.body,
                  color: LumiColors.subtext,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Language selector ─────────────────────────────────────────────────────────

class _LanguageSelector extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final l10n = AppLocalizations.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(LumiSpacing.md),
      decoration: BoxDecoration(
        color: LumiColors.surface,
        borderRadius: BorderRadius.circular(LumiRadii.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.profileLanguage,
            style: const TextStyle(
              fontSize: LumiTypeScale.labelMd,
              fontWeight: FontWeight.w600,
              color: LumiColors.subtext,
            ),
          ),
          const SizedBox(height: LumiSpacing.sm),
          Wrap(
            spacing: LumiSpacing.sm,
            runSpacing: LumiSpacing.xs,
            children: kSupportedLocales.map((locale) {
              final key = localeToKey(locale);
              final name = kLocaleDisplayNames[key] ?? locale.toString();
              final isActive = locale.languageCode == currentLocale.languageCode &&
                  locale.countryCode == currentLocale.countryCode;
              return GestureDetector(
                onTap: () => ref.read(localeProvider.notifier).setLocale(locale),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: LumiSpacing.md,
                    vertical: LumiSpacing.xs + 2,
                  ),
                  decoration: BoxDecoration(
                    gradient: isActive ? LumiColors.buttonGradient : null,
                    color: isActive ? null : LumiColors.baseAlt,
                    borderRadius: BorderRadius.circular(LumiRadii.pill),
                  ),
                  child: Text(
                    name,
                    style: TextStyle(
                      fontSize: LumiTypeScale.labelMd,
                      fontWeight:
                          isActive ? FontWeight.w600 : FontWeight.w400,
                      color: isActive ? LumiColors.onPrimary : LumiColors.subtext,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
