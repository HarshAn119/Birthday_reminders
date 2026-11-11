import 'package:birthday_reminders/entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 11, 10, 9);
  Entry? p(String s) => parseLine(s, now: now).entry;
  String? err(String s) => parseLine(s, now: now).error;

  test('parses the common Keep formats', () {
    expect(p('Rahul - 10 Nov 1996')!.toJson(), {'name': 'Rahul', 'day': 10, 'month': 11, 'year': 1996});
    expect(p('Priya Sharma: 14/11/1999')!.toJson(), {'name': 'Priya Sharma', 'day': 14, 'month': 11, 'year': 1999});
    expect(p('Mom & Dad anniv 2 Dec')!.toJson(), {'name': 'Mom & Dad anniv', 'day': 2, 'month': 12, 'year': null});
    expect(p('Karan V 19 December')!.toJson(), {'name': 'Karan V', 'day': 19, 'month': 12, 'year': null});
    expect(p('☐ March 3rd, 1990 – Neha')!.toJson(), {'name': 'Neha', 'day': 3, 'month': 3, 'year': 1990});
    expect(p('• Amit 05-08-01')!.toJson(), {'name': 'Amit', 'day': 5, 'month': 8, 'year': 2001});
    expect(p('Dev 7.6.85')!.year, 1985);
    expect(p('Mark 21st of June')!.month, 6);
  });

  test('does not read month names inside words', () {
    expect(p('Marriage day 4/5')!.toJson(), {'name': 'Marriage day', 'day': 4, 'month': 5, 'year': null});
  });

  test('flags bad lines instead of guessing', () {
    expect(err('Neha bday soon'), 'No date found');
    expect(err('Ravi 31/02'), "That date doesn't exist");
    expect(err('Baby 1/1/2030'), 'Year 2030 looks wrong');
    expect(err('Leap 29/02/2001'), '2001 had no 29 Feb');
    expect(err('14 March'), 'No name found');
    expect(parseLines('a 1/1\n\n  \nb 2/2', now: now).length, 2);
  });

  test('next occurrence, age and 29 Feb', () {
    final rahul = p('Rahul 10/11/1996')!;
    expect(rahul.daysUntil(now), 0);
    expect(rahul.ageIn(rahul.nextOn(now).year), 30);
    expect(p('Old 1/1')!.nextOn(now), DateTime(2027, 1, 1));
    final leap = p('Leap 29 Feb 2000')!;
    expect(leap.occurrenceIn(2027), DateTime(2027, 2, 28));
    expect(leap.occurrenceIn(2028), DateTime(2028, 2, 29));
  });

  test('upcoming skips today\'s past midnight, sorts, and caps', () {
    final es = [p('Rahul 10/11')!, p('Priya 14/11')!, p('Neha 3/1')!];
    final u = upcoming(es, now);
    expect(u.first.entry.name, 'Priya');
    expect(u.first.at, DateTime(2026, 11, 14));
    expect(u.where((o) => o.entry.name == 'Rahul').first.at, DateTime(2027, 11, 10));
    expect(upcoming(es, now, limit: 4).length, 4);
    expect(upcoming(es, now).length, 7); // 2026-2028, minus past dates and today
  });
}
