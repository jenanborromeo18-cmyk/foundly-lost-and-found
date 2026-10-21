import 'package:intl/intl.dart';

String formatDate(DateTime? date) {
  if (date == null) return 'Date not specified';
  return DateFormat('MMM d, yyyy').format(date.toLocal());
}

String relativeDate(DateTime date) {
  final difference = DateTime.now().difference(date.toLocal());
  if (difference.inMinutes < 1) return 'Just now';
  if (difference.inHours < 1) return '${difference.inMinutes}m ago';
  if (difference.inDays < 1) return '${difference.inHours}h ago';
  if (difference.inDays < 7) return '${difference.inDays}d ago';
  return DateFormat('MMM d').format(date.toLocal());
}
