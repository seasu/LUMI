import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/constants/lumi_colors.dart';
import '../../../shared/constants/lumi_spacing.dart';
import '../../auth/presentation/providers/auth_provider.dart';
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
      padding: const EdgeInsets.fromLTRB(24, LumiSpacing.md, 16, LumiSpacing.lg),
      children: [
        const Text(
          '個人檔案',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: LumiColors.text,
          ),
        ),
        const SizedBox(height: LumiSpacing.lg),
        // ── Avatar ─────────────────────────────────────────────────────────
        Center(
          child: CircleAvatar(
            radius: 48,
            backgroundColor: LumiColors.glow.withOpacity(0.3),
            backgroundImage: profile.photoUrl != null
                ? NetworkImage(profile.photoUrl!)
                : null,
            child: profile.photoUrl == null
                ? const Icon(Icons.person, size: 48, color: LumiColors.subtext)
                : null,
          ),
        ),
        const SizedBox(height: LumiSpacing.md),
        // ── Name ───────────────────────────────────────────────────────────
        Center(
          child: Text(
            profile.displayName.isEmpty ? profile.email : profile.displayName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: LumiColors.text,
            ),
          ),
        ),
        const SizedBox(height: LumiSpacing.lg),
        // ── Measurements section ───────────────────────────────────────────
        const Text(
          '個人身材數據',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: LumiColors.subtext,
          ),
        ),
        const SizedBox(height: LumiSpacing.md),
        _MeasurementsGrid(profile: profile),
        const SizedBox(height: LumiSpacing.xl),
        // ── Logout ─────────────────────────────────────────────────────────
        OutlinedButton(
          onPressed: () => signOut(ref),
          style: OutlinedButton.styleFrom(
            foregroundColor: LumiColors.subtext,
            side: BorderSide(color: LumiColors.subtext.withOpacity(0.55)),
            padding: const EdgeInsets.symmetric(vertical: LumiSpacing.md),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(9999),
            ),
          ),
          child: const Text('登出'),
        ),
        const SizedBox(height: LumiSpacing.lg),
      ],
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
          value: p.heightCm != null ? '${p.heightCm!.toStringAsFixed(0)} cm' : '—',
          unit: 'cm',
          currentValue: p.heightCm?.toString(),
        ),
        _MeasurementItem(
          icon: Icons.monitor_weight_outlined,
          label: '體重',
          field: 'weightKg',
          value: p.weightKg != null ? '${p.weightKg!.toStringAsFixed(0)} kg' : '—',
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
          value: p.chestCm != null ? '${p.chestCm!.toStringAsFixed(0)} cm' : '—',
          unit: 'cm',
          currentValue: p.chestCm?.toString(),
        ),
        _MeasurementItem(
          icon: Icons.straighten_outlined,
          label: '腰圍',
          field: 'waistCm',
          value: p.waistCm != null ? '${p.waistCm!.toStringAsFixed(0)} cm' : '—',
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
    // Accepts "YYYY-MM-DD"
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
          borderRadius: BorderRadius.circular(16),
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
                      fontSize: 11,
                      color: LumiColors.subtext,
                    ),
                  ),
                  Text(
                    item.value,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: LumiColors.text,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                size: 16, color: LumiColors.subtext),
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
            parsed = value; // store as string "YYYY-MM-DD"
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
    _ctrl = TextEditingController(
      text: widget.item.currentValue ?? '',
    );
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            LumiSpacing.lg, LumiSpacing.lg, LumiSpacing.lg, LumiSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '修改${widget.item.label}',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: LumiColors.text,
              ),
            ),
            const SizedBox(height: LumiSpacing.lg),
            // Large number input
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
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w300,
                      color: LumiColors.text,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                    ),
                  ),
                ),
                if (widget.item.unit.isNotEmpty)
                  Text(
                    ' ${widget.item.unit}',
                    style: const TextStyle(
                      fontSize: 20,
                      color: LumiColors.subtext,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: LumiSpacing.lg),
            // Save button
            GestureDetector(
              onTap: _saving ? null : _save,
              child: Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  gradient: _saving ? null : LumiColors.buttonGradient,
                  color: _saving
                      ? LumiColors.primary.withOpacity(0.5)
                      : null,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Center(
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          '儲存',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
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
                style:
                    TextStyle(fontSize: 15, color: LumiColors.subtext),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
