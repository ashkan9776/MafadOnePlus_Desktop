enum LogType { info, success, warning, error, command }

class LogEntry {
  final DateTime timestamp;
  final String title;
  final String message;
  final LogType type;
  final String? command;

  LogEntry({
    DateTime? timestamp,
    required this.title,
    required this.message,
    this.type = LogType.info,
    this.command,
  }) : timestamp = timestamp ?? DateTime.now();

  String get timeFormatted {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    final s = timestamp.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}
