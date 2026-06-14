/// 最終練習日時を「今日 / 昨日 / N 日前」の相対表示にする(pure Dart)。
/// 未練習(null)は「—」。時刻ではなく**日付の差**で判定する。
String relativePracticeLabel(DateTime? last, DateTime now) {
  if (last == null) return '—';
  final today = DateTime(now.year, now.month, now.day);
  final lastDay = DateTime(last.year, last.month, last.day);
  final days = today.difference(lastDay).inDays;
  if (days <= 0) return '今日';
  if (days == 1) return '昨日';
  return '$days 日前';
}
