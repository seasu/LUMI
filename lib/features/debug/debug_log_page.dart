import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/debug/debug_log.dart';
import '../../shared/constants/lumi_colors.dart';
import '../../shared/constants/lumi_spacing.dart';
import '../snap/data/cloud_functions_service.dart';

class DebugLogPage extends ConsumerStatefulWidget {
  const DebugLogPage({super.key});

  @override
  ConsumerState<DebugLogPage> createState() => _DebugLogPageState();
}

class _DebugLogPageState extends ConsumerState<DebugLogPage> {
  final _scrollCtrl = ScrollController();
  final _service = DebugLogService.instance;
  String? _serverVersion;

  @override
  void initState() {
    super.initState();
    _service.addListener(_onLog);
    _fetchServerVersion();
  }

  Future<void> _fetchServerVersion() async {
    final v = await ref.read(cloudFunctionsServiceProvider).getServerVersion();
    if (mounted) setState(() => _serverVersion = v);
  }

  @override
  void dispose() {
    _service.removeListener(_onLog);
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onLog() {
    if (!mounted) return;
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
      }
    });
  }

  Future<void> _copyAll() async {
    await Clipboard.setData(ClipboardData(text: _service.exportAll()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已複製所有 log')),
    );
  }

  Future<void> _shareAll() async {
    final text = _service.exportAll();
    if (text.isEmpty) return;
    await Share.share(text, subject: 'Lumi Debug Log');
  }

  @override
  Widget build(BuildContext context) {
    final entries = _service.entries;

    return Scaffold(
      backgroundColor: LumiColors.base,
      appBar: AppBar(
        backgroundColor: LumiColors.base,
        foregroundColor: LumiColors.text,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Debug Log (${entries.length})',
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              _serverVersion == null
                  ? 'Server: …'
                  : 'Server v$_serverVersion',
              style: const TextStyle(
                fontSize: 11,
                color: LumiColors.subtext,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_all_outlined, size: 20),
            tooltip: '複製全部',
            onPressed: _copyAll,
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined, size: 20),
            tooltip: '分享',
            onPressed: _shareAll,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            tooltip: '清除',
            onPressed: () {
              _service.clear();
              setState(() {});
            },
          ),
        ],
      ),
      body: entries.isEmpty
          ? const Center(
              child: Text(
                '（無 log）',
                style: TextStyle(color: LumiColors.subtext, fontSize: 14),
              ),
            )
          : ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.symmetric(
                horizontal: LumiSpacing.sm,
                vertical: LumiSpacing.xs,
              ),
              itemCount: entries.length,
              itemBuilder: (context, i) => _LogEntryRow(
                key: ValueKey(i),
                entry: entries[i],
              ),
            ),
    );
  }
}

// ── Tag colour palette (debug UI — exempt from LumiColors rule) ──────────────

Color _tagColor(String? tag) => switch (tag) {
      'fn' => const Color(0xFF7C9EFF),
      'auth' => const Color(0xFF66BB6A),
      'token' => const Color(0xFFFF9800),
      'fs:user' || 'fs:wardrobe' => const Color(0xFF26C6DA),
      _ => const Color(0xFF888888),
    };

String? _parseTag(String message) =>
    RegExp(r'^\[([^\]]+)\] ').firstMatch(message)?.group(1);

String _stripTag(String message, String? tag) =>
    tag != null ? message.replaceFirst('[$tag] ', '') : message;

// ── Per-entry row ─────────────────────────────────────────────────────────────

class _LogEntryRow extends StatefulWidget {
  const _LogEntryRow({super.key, required this.entry});
  final DebugLogEntry entry;

  @override
  State<_LogEntryRow> createState() => _LogEntryRowState();
}

class _LogEntryRowState extends State<_LogEntryRow> {
  bool _expanded = false;

  String get _timeLabel {
    final t = widget.entry.time;
    return '${t.hour.toString().padLeft(2, '0')}:'
        '${t.minute.toString().padLeft(2, '0')}:'
        '${t.second.toString().padLeft(2, '0')}.'
        '${t.millisecond.toString().padLeft(3, '0')}';
  }

  bool get _isError => widget.entry.message.contains('✗');

  Future<void> _copyEntry() async {
    await Clipboard.setData(
      ClipboardData(text: widget.entry.formatted),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        const SnackBar(
          content: Text('已複製'),
          duration: Duration(milliseconds: 1200),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final tag = _parseTag(widget.entry.message);
    final body = _stripTag(widget.entry.message, tag);
    final lines = body.split('\n');
    final isMultiLine = lines.length > 1;
    final displayText =
        (!_expanded && isMultiLine) ? lines.first : body;
    final tagColor = _tagColor(tag);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: LumiColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: _isError
            ? const Border(
                left: BorderSide(color: Color(0xFFFF5252), width: 3),
              )
            : null,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: isMultiLine
            ? () => setState(() => _expanded = !_expanded)
            : null,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 7, 4, 7),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Time ───────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Text(
                  _timeLabel,
                  style: const TextStyle(
                    fontSize: 9,
                    color: LumiColors.subtext,
                    fontFamily: 'monospace',
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // ── Tag pill ───────────────────────────────────────────────────
              if (tag != null) ...[
                Container(
                  margin: const EdgeInsets.only(top: 1),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: tagColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: tagColor,
                      fontFamily: 'monospace',
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              // ── Message ────────────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayText,
                      style: TextStyle(
                        fontSize: 11,
                        color: _isError
                            ? const Color(0xFFFF6B6B)
                            : LumiColors.text,
                        fontFamily: 'monospace',
                        height: 1.45,
                      ),
                    ),
                    if (isMultiLine) ...[
                      const SizedBox(height: 2),
                      Text(
                        _expanded
                            ? '▲ 收合'
                            : '▼ 展開 (${lines.length} 行)',
                        style: TextStyle(
                          fontSize: 9,
                          color: tagColor.withValues(alpha: 0.7),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // ── Copy icon ──────────────────────────────────────────────────
              GestureDetector(
                onTap: _copyEntry,
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(
                    Icons.copy_outlined,
                    size: 14,
                    color: LumiColors.subtext,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
