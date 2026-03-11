import 'package:intl/intl.dart';

String _resolvedLocale(String? locale) {
  if (locale != null && locale.isNotEmpty) return locale;
  final current = Intl.getCurrentLocale();
  if (current.isNotEmpty && current != 'C') return current;
  return 'en_US';
}

/// Format seconds into HH:MM:SS or MM:SS string
String formatDuration(int totalSeconds) {
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final seconds = totalSeconds % 60;

  if (hours > 0) {
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}

/// Format DateTime to readable date + time string
String formatDate(DateTime date, {String? locale}) {
  return DateFormat.yMMMMd(_resolvedLocale(locale)).format(date);
}

/// Format DateTime to date + time string (e.g., "1 Mart 2026 • 13:14")
String formatDateWithTime(DateTime date, {String? locale}) {
  final resolved = _resolvedLocale(locale);
  final datePart = DateFormat.yMMMMd(resolved).format(date);
  final timePart = DateFormat.Hm(resolved).format(date);
  return '$datePart  •  $timePart';
}

/// Format short date
String formatShortDate(DateTime date, {String? locale}) {
  return DateFormat.yMd(_resolvedLocale(locale)).format(date);
}

/// Format time to HH:MM format
String formatTime(DateTime date) {
  return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}
