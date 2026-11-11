/// A yearly date (birthday, anniversary…) and the plain-text parser that
/// turns lines like "Rahul - 14 March 1996" into entries.
class Entry {
  final String name;
  final int day;
  final int month;
  final int? year;

  const Entry(this.name, this.day, this.month, [this.year]);

  Map<String, dynamic> toJson() => {'name': name, 'day': day, 'month': month, 'year': year};
  factory Entry.fromJson(Map<String, dynamic> j) =>
      Entry(j['name'] as String, j['day'] as int, j['month'] as int, j['year'] as int?);

  /// Midnight of the next time this date comes round, today included.
  DateTime nextOn(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    var d = occurrenceIn(now.year);
    if (d.isBefore(today)) d = occurrenceIn(now.year + 1);
    return d;
  }

  /// 29 Feb falls back to 28 Feb in non-leap years.
  DateTime occurrenceIn(int y) =>
      (month == 2 && day == 29 && !_isLeap(y)) ? DateTime(y, 2, 28) : DateTime(y, month, day);

  /// Age (or years since) reached on the occurrence in year [y]; null when no birth year.
  int? ageIn(int y) => year == null ? null : y - year!;

  int daysUntil(DateTime now) =>
      nextOn(now).difference(DateTime(now.year, now.month, now.day)).inDays;
}

bool _isLeap(int y) => y % 4 == 0 && (y % 100 != 0 || y % 400 == 0);
const _daysIn = [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];

const monthShort = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const monthLong = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December'
];

const _mon = r'(january|jan|february|feb|march|mar|april|apr|may|june|jun|july|jul|august|aug|september|sept|sep|october|oct|november|nov|december|dec)\.?';
final _numeric = RegExp(r'(?<!\d)(\d{1,2})[/\-.](\d{1,2})(?:[/\-.](\d{4}|\d{2}))?(?!\d)');
final _dayMonth = RegExp('(?<!\\d)(\\d{1,2})(?:st|nd|rd|th)?\\s*(?:of\\s+)?$_mon(?![a-z])(?:,?\\s*(\\d{4}))?', caseSensitive: false);
final _monthDay = RegExp('(?<![a-z])$_mon\\s+(\\d{1,2})(?:st|nd|rd|th)?(?!\\d)(?:,?\\s*(\\d{4}))?', caseSensitive: false);

int _monthNum(String s) {
  final k = s.toLowerCase().substring(0, 3);
  return monthShort.indexWhere((m) => m.toLowerCase() == k) + 1;
}

/// Result of parsing one line: either an [entry] or an [error] to show the user.
class ParsedLine {
  final String line;
  final Entry? entry;
  final String? error;
  const ParsedLine(this.line, {this.entry, this.error});
}

/// Day comes before month in numeric dates (14/03 = 14 March).
List<ParsedLine> parseLines(String text, {DateTime? now}) => text
    .split('\n')
    .map((l) => l.trim())
    .where((l) => l.isNotEmpty)
    .map((l) => parseLine(l, now: now ?? DateTime.now()))
    .toList();

ParsedLine parseLine(String line, {required DateTime now}) {
  int? day, month, year;
  RegExpMatch? m = _dayMonth.firstMatch(line);
  if (m != null) {
    day = int.parse(m[1]!);
    month = _monthNum(m[2]!);
    year = m[3] == null ? null : int.parse(m[3]!);
  } else if ((m = _monthDay.firstMatch(line)) != null) {
    month = _monthNum(m![1]!);
    day = int.parse(m[2]!);
    year = m[3] == null ? null : int.parse(m[3]!);
  } else if ((m = _numeric.firstMatch(line)) != null) {
    day = int.parse(m![1]!);
    month = int.parse(m[2]!);
    if (m[3] != null) {
      year = int.parse(m[3]!);
      if (m[3]!.length == 2) year += year <= now.year % 100 ? 2000 : 1900;
    }
  }
  if (m == null) return ParsedLine(line, error: 'No date found');
  if (month! < 1 || month > 12 || day! < 1 || day > _daysIn[month - 1]) {
    return ParsedLine(line, error: "That date doesn't exist");
  }
  if (year != null && (year > now.year || year < 1900)) {
    return ParsedLine(line, error: 'Year $year looks wrong');
  }
  if (year != null && month == 2 && day == 29 && !_isLeap(year)) {
    return ParsedLine(line, error: '$year had no 29 Feb');
  }
  final name = '${line.substring(0, m.start)} ${line.substring(m.end)}'
      .replaceAll(RegExp(r'^[\s\-–—*•·☐☑✓✔:,|]+|[\s\-–—:,|]+$'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (name.isEmpty) return ParsedLine(line, error: 'No name found');
  return ParsedLine(line, entry: Entry(name, day, month, year));
}

/// One reminder to schedule: who, and the midnight it fires.
class Occurrence {
  final Entry entry;
  final DateTime at;
  const Occurrence(this.entry, this.at);
}

/// The next [limit] midnights across all entries, soonest first, looking [years] ahead.
/// Today's midnight is already past, so it is excluded.
List<Occurrence> upcoming(List<Entry> entries, DateTime now, {int limit = 64, int years = 2}) {
  final out = <Occurrence>[
    for (final e in entries)
      for (var y = now.year; y <= now.year + years; y++)
        if (e.occurrenceIn(y).isAfter(now)) Occurrence(e, e.occurrenceIn(y)),
  ]..sort((a, b) => a.at.compareTo(b.at));
  return out.take(limit).toList();
}
