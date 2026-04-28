import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/debug/debug_log.dart';
import '../../shared/constants/lumi_colors.dart';
import '../../shared/constants/lumi_spacing.dart';

class DebugLogPage extends StatefulWidget {
  const DebugLogPage({super.key});

  @override
  State<DebugLogPage> createState() => _DebugLogPageState();
}

class _DebugLogPageState extends State<DebugLogPage> {
  final _scrollCtrl = ScrollController();
  final _service = DebugLogService.instance;

  @override
  void initState() {
    super.initState();
    _service.addListener(_onLog);
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
        title: const Text('Debug Log', style: TextStyle(fontSize: 16)),
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
              child: Text('（無 log）',
                  style: TextStyle(color: LumiColors.subtext, fontSize: 14)),
            )
          : ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.symmetric(
                  horizontal: LumiSpacing.md, vertical: LumiSpacing.sm),
              itemCount: entries.length,
              itemBuilder: (context, i) {
                final entry = entries[i];
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 1),
                  child: Text(
                    entry.formatted,
                    style: const TextStyle(
                      fontSize: 11,
                      color: LumiColors.text,
                      fontFamily: 'monospace',
                      height: 1.4,
                    ),
                  ),
                );
              },
            ),
    );
  }
}
