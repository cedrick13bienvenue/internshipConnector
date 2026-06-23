import 'package:intl/intl.dart';

class DateFormatter {
  static String timeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 30) return DateFormat('MMM d, y').format(date);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  static String format(DateTime date) => DateFormat('MMM d, y').format(date);

  static String formatDeadline(DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(now);
    if (diff.inDays < 0) return 'Closed';
    if (diff.inDays == 0) return 'Closes today';
    if (diff.inDays == 1) return 'Closes tomorrow';
    if (diff.inDays < 7) return 'Closes in ${diff.inDays} days';
    return 'Closes ${DateFormat('MMM d').format(date)}';
  }
}
