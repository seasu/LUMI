import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/constants/app_version.dart';
import '../../../shared/constants/lumi_colors.dart';
import '../../../shared/constants/lumi_radii.dart';
import '../../../shared/constants/lumi_spacing.dart';
import '../../../shared/constants/lumi_type_scale.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../debug/debug_log_page.dart';
import '../../purchase/presentation/widgets/paywall_sheet.dart';
import '../../user/data/user_profile.dart';
import '../../user/data/user_repository.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final profile = profileAsync.valueOrNull;

    return Scaffold(
      backgroundColor: LumiColors.base,
      body: SafeArea(
        child: profile == null
            ? const Center(
                child: CircularProgressIndicator(color: LumiColors.primary),
              )
            : _ProfileContent(profile: profile),
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
        const Text(
          '個人檔案',
          style: TextStyle(
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
        const Text(
          '個人身材數據',
          textAlign: TextAlign.center,
          style: TextStyle(
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
          child: const Text('登出'),
        ),
        const SizedBox(height: LumiSpacing.lg),
      ],
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
              const Text(
                'AI 分析配額',
                style: TextStyle(
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
                  '$used / $quota 件',
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
            const Text(
              '無限 AI 分析，享受 Pro 會員',
              style: TextStyle(
                fontSize: LumiTypeScale.labelMd,
                color: LumiColors.subtext,
              ),
            )
          else
            Text(
              isNearLimit
                  ? '剩餘 $remaining 件，即將用完'
                  : '剩餘 $remaining 件可分析',
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
                child: const Text(
                  '升級 Pro 或購買補充包',
                  textAlign: TextAlign.center,
                  style: TextStyle(
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
            content: Text('再點 ${5 - _taps} 次開啟 Debug Log'),
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
      child: const _InfoRow(label: '版本', value: appVersionLabel),
    );
  }
}

// ── Measurements 2-column grid ────────────────────────────────────────────────

class _MeasurementsGrid extends StatelessWidget {
  const _MeasurementsGrid({required this.profile});
  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final items = _measurementItems(profile);
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

  List<_MeasurementItem> _measurementItems(UserProfile p) => [
        _MeasurementItem(
          icon: Icons.accessibility_new_outlined,
          label: '身高',
          field: 'heightCm',
          value: p.heightCm != null
              ? '${p.heightCm!.toStringAsFixed(0)} cm'
              : '—',
          unit: 'cm',
          currentValue: p.heightCm?.toString(),
        ),
        _MeasurementItem(
          icon: Icons.monitor_weight_outlined,
          label: '體重',
          field: 'weightKg',
          value: p.weightKg != null
              ? '${p.weightKg!.toStringAsFixed(0)} kg'
              : '—',
          unit: 'kg',
          currentValue: p.weightKg?.toString(),
        ),
        _MeasurementItem(
          icon: Icons.calendar_today_outlined,
          label: '生日',
          field: 'birthday',
          value: p.birthday != null ? _formatBirthday(p.birthday!) : '—',
          unit: '',
          currentValue: p.birthday,
          isDate: true,
        ),
        _MeasurementItem(
          icon: Icons.face_outlined,
          label: '頭圍',
          field: 'headCircumferenceCm',
          value: p.headCircumferenceCm != null
              ? '${p.headCircumferenceCm!.toStringAsFixed(0)} cm'
              : '—',
          unit: 'cm',
          currentValue: p.headCircumferenceCm?.toString(),
        ),
        _MeasurementItem(
          icon: Icons.favorite_border,
          label: '胸圍',
          field: 'chestCm',
          value:
              p.chestCm != null ? '${p.chestCm!.toStringAsFixed(0)} cm' : '—',
          unit: 'cm',
          currentValue: p.chestCm?.toString(),
        ),
        _MeasurementItem(
          icon: Icons.straighten_outlined,
          label: '腰圍',
          field: 'waistCm',
          value:
              p.waistCm != null ? '${p.waistCm!.toStringAsFixed(0)} cm' : '—',
          unit: 'cm',
          currentValue: p.waistCm?.toString(),
        ),
        _MeasurementItem(
          icon: Icons.airline_seat_legroom_normal_outlined,
          label: '臀圍',
          field: 'hipCm',
          value: p.hipCm != null ? '${p.hipCm!.toStringAsFixed(0)} cm' : '—',
          unit: 'cm',
          currentValue: p.hipCm?.toString(),
        ),
        _MeasurementItem(
          icon: Icons.directions_walk_outlined,
          label: '腿長',
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
              '修改${widget.item.label}',
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
                      : const Text(
                          '儲存',
                          style: TextStyle(
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
              child: const Text(
                '取消',
                style: TextStyle(
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
