import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/log_entry.dart';
import '../services/adb_service.dart';
import '../theme/app_theme.dart';

class ConsoleSheet extends StatefulWidget {
  final AdbService adbService;
  final VoidCallback onClose;

  const ConsoleSheet({
    super.key,
    required this.adbService,
    required this.onClose,
  });

  @override
  State<ConsoleSheet> createState() => _ConsoleSheetState();
}

class _ConsoleSheetState extends State<ConsoleSheet> {
  final TextEditingController _cmdCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  bool _isExecuting = false;

  @override
  void dispose() {
    _cmdCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _executeCustomCmd() async {
    final text = _cmdCtrl.text.trim();
    if (text.isEmpty) return;
    _cmdCtrl.clear();

    setState(() => _isExecuting = true);
    try {
      final selectedSerial = widget.adbService.selectedDevice?.serial;
      await widget.adbService.runRawCommand(text, deviceSerial: selectedSerial);
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _isExecuting = false);
      }
    }
  }

  void _copyAllLogs() {
    final buffer = StringBuffer();
    for (final l in widget.adbService.logs.reversed) {
      buffer.writeln('[${l.timeFormatted}] ${l.title}');
      if (l.command != null) buffer.writeln('> ${l.command}');
      buffer.writeln(l.message);
      buffer.writeln('----------------------------------------');
    }
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تمامی لاگ‌ها در کلیپ‌بورد کپی شد.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final logs = widget.adbService.logs;

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(
          top: BorderSide(color: AppTheme.border, width: 1.5),
        ),
      ),
      child: Column(
        children: [
          // Console Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              color: AppTheme.surfaceLight,
              border: Border(
                bottom: BorderSide(color: AppTheme.border),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.terminal_rounded,
                    size: 18, color: AppTheme.primary),
                const SizedBox(width: 8),
                const Text(
                  'کنسول و گزارش‌های زنده ADB',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textMain,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${logs.length}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  tooltip: 'کپی تمام لاگ‌ها',
                  color: AppTheme.textMuted,
                  onPressed: logs.isEmpty ? null : _copyAllLogs,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 16),
                  tooltip: 'پاک کردن کنسول',
                  color: AppTheme.textMuted,
                  onPressed: widget.adbService.clearLogs,
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  tooltip: 'بستن کنسول',
                  color: AppTheme.textMuted,
                  onPressed: widget.onClose,
                ),
              ],
            ),
          ),

          // Log List
          Expanded(
            child: logs.isEmpty
                ? const Center(
                    child: Text(
                      'هیچ رویدادی هنوز ثبت نشده است.',
                      style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(12),
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final item = logs[index];
                      return _buildLogTile(item);
                    },
                  ),
          ),

          // Command Input Field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: const BoxDecoration(
              color: AppTheme.surfaceLight,
              border: Border(top: BorderSide(color: AppTheme.border)),
            ),
            child: Row(
              children: [
                const Text(
                  'adb >',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _cmdCtrl,
                    onSubmitted: (_) => _executeCustomCmd(),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: AppTheme.textMain,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'اجرای دستور دلخواه (مثلاً: shell getprop, devices)...',
                      hintStyle: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 11,
                        color: AppTheme.textMuted,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _isExecuting ? null : _executeCustomCmd,
                  icon: _isExecuting
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.primary,
                          ),
                        )
                      : const Icon(Icons.send_rounded,
                          size: 16, color: AppTheme.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogTile(LogEntry item) {
    Color color;
    IconData icon;

    switch (item.type) {
      case LogType.success:
        color = AppTheme.primary;
        icon = Icons.check_circle_rounded;
        break;
      case LogType.error:
        color = AppTheme.error;
        icon = Icons.error_outline_rounded;
        break;
      case LogType.warning:
        color = AppTheme.warning;
        icon = Icons.warning_amber_rounded;
        break;
      case LogType.command:
        color = AppTheme.secondary;
        icon = Icons.terminal_rounded;
        break;
      case LogType.info:
        color = AppTheme.textMuted;
        icon = Icons.info_outline;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                item.title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const Spacer(),
              Text(
                item.timeFormatted,
                style: const TextStyle(
                  fontSize: 10,
                  fontFamily: 'monospace',
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
          if (item.command != null) ...[
            const SizedBox(height: 4),
            Text(
              '> ${item.command}',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                color: AppTheme.secondary,
              ),
            ),
          ],
          const SizedBox(height: 4),
          SelectableText(
            item.message,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              color: AppTheme.textMain,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
