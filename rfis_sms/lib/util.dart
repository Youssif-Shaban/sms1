const List<String> kMonthsAr = [
  'يناير',
  'فبراير',
  'مارس',
  'أبريل',
  'مايو',
  'يونيو',
  'يوليو',
  'أغسطس',
  'سبتمبر',
  'أكتوبر',
  'نوفمبر',
  'ديسمبر',
];

const List<String> kMonthsEn = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// Sunday-first, to match the portal calendar.
const List<String> kDaysAr = [
  'الأحد',
  'الاثنين',
  'الثلاثاء',
  'الأربعاء',
  'الخميس',
  'الجمعة',
  'السبت',
];

const List<String> kDaysEn = [
  'Sunday',
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
];

const List<String> kDaysShortAr = [
  'أحد',
  'اثنين',
  'ثلاثاء',
  'أربعاء',
  'خميس',
  'جمعة',
  'سبت',
];

const List<String> kDaysShortEn = [
  'Sun',
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
];

String twoDigits(int n) => n.toString().padLeft(2, '0');

/// yyyy-MM-dd
String iso(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${twoDigits(d.month)}-${twoDigits(d.day)}';

DateTime? parseIso(String s) {
  if (s.length < 10) return null;
  try {
    final parts = s.substring(0, 10).split('-');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  } catch (_) {
    return null;
  }
}

/// dd/MM/yyyy (the portal date format is d/m/Y).
String fmtDate(String s) {
  final d = parseIso(s);
  if (d == null) return s;
  return '${twoDigits(d.day)}/${twoDigits(d.month)}/${d.year}';
}

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime today() => dateOnly(DateTime.now());

/// Adds whole calendar days without time-zone / DST drift.
DateTime addDays(DateTime d, int days) =>
    DateTime(d.year, d.month, d.day + days);

bool sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Sunday = 0 ... Saturday = 6
int sundayIndex(DateTime d) => d.weekday % 7;

String nowTime() {
  final n = DateTime.now();
  return '${twoDigits(n.hour)}:${twoDigits(n.minute)}';
}

/// Grade scale: A >= 90, B >= 80, C >= 70, D >= 60, otherwise F.
String gradeFor(double pct) {
  if (pct >= 90) return 'A';
  if (pct >= 80) return 'B';
  if (pct >= 70) return 'C';
  if (pct >= 60) return 'D';
  return 'F';
}

String fmtNum(double v) {
  if (v == v.roundToDouble()) return v.toStringAsFixed(0);
  return v.toStringAsFixed(1);
}

/// SMS segments: 160 characters per segment for Latin text,
/// 70 per segment when the text contains non-Latin (Unicode) characters.
int smsSegments(String text) {
  if (text.isEmpty) return 0;
  final unicode = text.runes.any((r) => r > 127);
  final limit = unicode ? 70 : 160;
  final length = text.runes.length;
  return (length + limit - 1) ~/ limit;
}

String applyVars(String text, Map<String, String> vars) {
  var out = text;
  vars.forEach((key, value) {
    out = out.replaceAll('{$key}', value);
  });
  return out;
}

String csvCell(String s) => '"${s.replaceAll('"', '""')}"';

bool isValidTime(String s) => RegExp(r'^([01]?\d|2[0-3]):[0-5]\d$').hasMatch(s);

int timeToMinutes(String s) {
  final p = s.split(':');
  return int.parse(p[0]) * 60 + int.parse(p[1]);
}

String normalizeTime(String s) {
  final p = s.split(':');
  return '${twoDigits(int.parse(p[0]))}:${p[1]}';
}
