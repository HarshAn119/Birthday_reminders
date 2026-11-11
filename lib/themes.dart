import 'dart:math';

import 'package:flutter/material.dart';

import 'entry.dart';

/// One visual personality: colours, fonts, the home-screen pieces, and the
/// notification wording (notifications can't be styled, so copy carries the theme).
abstract class BdayTheme {
  String get id;
  String get label;
  String get tagline;
  Brightness get brightness;
  Color get bg;
  Color get ink;
  Color get muted;
  Color get accent;
  Color get card;
  String get display;
  String get body;

  Widget background();
  Widget header(List<Entry> today, Entry? next, DateTime now);
  Widget hero(List<Entry> today, Entry? next, DateTime now);
  Widget row(Entry e, DateTime now, int index);
  (String, String) notification(Entry e, int? age);

  TextStyle t(double size, {FontWeight w = FontWeight.w400, Color? c, String? f, FontStyle? s, double? h}) =>
      TextStyle(fontFamily: f ?? body, fontSize: size, fontWeight: w, color: c ?? ink, fontStyle: s, height: h);
}

final themes = <BdayTheme>[Scrapbook(), Confetti(), Midnight()];
BdayTheme themeById(String? id) => themes.firstWhere((t) => t.id == id, orElse: () => themes.first);

String names(List<Entry> es) => es.length == 1
    ? es.first.name
    : '${es.take(es.length - 1).map((e) => e.name).join(', ')} & ${es.last.name}';

String inDays(int d, [String unit = 'day']) =>
    d == 0 ? 'today' : d == 1 ? (unit == 'day' ? 'tomorrow' : '1 $unit') : 'in $d ${unit}s';

String detail(Entry e, DateTime now) {
  final age = e.ageIn(e.nextOn(now).year);
  final anniv = e.name.toLowerCase().contains('anniv');
  if (age == null) return anniv ? 'anniversary' : 'birthday';
  return anniv ? '$age years together' : 'turning $age';
}

// ─── Scrapbook ──────────────────────────────────────────────────────────────

class Scrapbook extends BdayTheme {
  @override final id = 'scrapbook';
  @override final label = 'Scrapbook';
  @override final tagline = 'Warm, handwritten, a diary of people you love';
  @override final brightness = Brightness.light;
  @override final bg = const Color(0xFFF6EFE3);
  @override final ink = const Color(0xFF3B2F25);
  @override final muted = const Color(0xFF7A6550);
  @override final accent = const Color(0xFFB5533C);
  @override final card = const Color(0xFFFBF7F0);
  @override final display = 'Fraunces';
  @override final body = 'Fraunces';

  @override
  Widget background() => CustomPaint(painter: _Dots(const Color(0xFFE6DCCB)), size: Size.infinite);

  @override
  Widget header(today, next, now) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(monthLong[now.month - 1], style: t(24, f: 'Caveat', w: FontWeight.w700, c: accent)),
        Text.rich(TextSpan(children: [
          TextSpan(text: 'The people\n', style: t(34, w: FontWeight.w600, h: 1.05)),
          TextSpan(text: 'worth remembering', style: t(34, s: FontStyle.italic, h: 1.05)),
        ])),
      ]);

  @override
  Widget hero(today, next, now) {
    final String hand, line;
    if (today.isNotEmpty) {
      final e = today.first;
      final age = e.ageIn(now.year);
      hand = today.length > 1 ? "It's ${names(today)}'s day!" : age == null ? "It's ${e.name}'s birthday!" : '${e.name} turns $age today!';
      line = e.year == null ? 'Call before breakfast.' : 'Born ${e.day} ${monthShort[e.month - 1]} ${e.year} · call before breakfast.';
    } else if (next != null) {
      hand = 'Next up: ${next.name}';
      line = '${inDays(next.daysUntil(now))[0].toUpperCase()}${inDays(next.daysUntil(now)).substring(1)} · ${next.day} ${monthLong[next.month - 1]}';
    } else {
      hand = 'Your scrapbook is empty';
      line = 'Tap + and paste your list to fill it.';
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 18),
      child: Transform.rotate(
        angle: 0.02,
        child: Stack(clipBehavior: Clip.none, children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
            decoration: const BoxDecoration(color: Colors.white, boxShadow: [
              BoxShadow(color: Color(0x40502814), blurRadius: 14, offset: Offset(0, 6), spreadRadius: -6),
            ]),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(hand, style: t(30, f: 'Caveat', w: FontWeight.w700, c: accent, h: 1)),
              const SizedBox(height: 6),
              Text(line, style: t(14)),
            ]),
          ),
          Positioned(
            top: -10,
            left: 0,
            right: 0,
            child: Center(
              child: Transform.rotate(
                angle: -0.05,
                child: Container(width: 80, height: 22, color: const Color(0xB3E8C478)),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  @override
  Widget row(e, now, index) => Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(children: [
            Container(
              width: 50,
              height: 56,
              decoration: BoxDecoration(color: card, border: Border.all(color: ink, width: 2)),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(monthShort[e.month - 1].toUpperCase(),
                    style: TextStyle(fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.w600, color: ink)),
                Text('${e.day}', style: t(22, w: FontWeight.w600, h: 1.1)),
              ]),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(e.name, style: t(17, w: FontWeight.w600), overflow: TextOverflow.ellipsis),
                Text(detail(e, now), style: t(18, f: 'Caveat', w: FontWeight.w700, c: muted)),
              ]),
            ),
            Text(inDays(e.daysUntil(now)), style: TextStyle(fontSize: 12, color: muted)),
          ]),
        ),
        CustomPaint(painter: _Dash(const Color(0xFFCDBBA0)), size: const Size(double.infinity, 1)),
      ]);

  @override
  (String, String) notification(e, age) => (
        "Today is ${e.name}'s birthday",
        age == null ? 'Make it count.' : '$age years of ${e.name}. Make it count.',
      );
}

// ─── Confetti ───────────────────────────────────────────────────────────────

class Confetti extends BdayTheme {
  @override final id = 'confetti';
  @override final label = 'Confetti';
  @override final tagline = 'Loud, playful, a party in your pocket';
  @override final brightness = Brightness.light;
  @override final bg = const Color(0xFFFFF4DE);
  @override final ink = const Color(0xFF1E1B3A);
  @override final muted = const Color(0xB31E1B3A);
  @override final accent = const Color(0xFFFF5A5F);
  @override final card = Colors.white;
  @override final display = 'Bricolage';
  @override final body = 'Bricolage';
  static const _rows = [Color(0xFFFFD23F), Color(0xFF3EC1D3), Color(0xFFC7B8FF), Color(0xFFFF9F6B)];

  @override
  Widget background() => const SizedBox.expand();

  @override
  Widget header(today, next, now) =>
      Text("Who's\nnext? 🎈", style: t(30, w: FontWeight.w800, h: 1));

  @override
  Widget hero(today, next, now) {
    final String small, big, sub;
    if (today.isNotEmpty) {
      final age = today.first.ageIn(now.year);
      small = "IT'S TODAY!";
      big = today.length == 1 && age != null ? '${today.first.name} hits $age 🎉' : '${names(today)} 🎉';
      sub = 'Go embarrass them in the group chat.';
    } else if (next != null) {
      small = 'NEXT PARTY';
      big = '${next.name} ${inDays(next.daysUntil(now))}';
      sub = 'Start planning the chaos.';
    } else {
      small = 'NO PARTIES YET';
      big = 'Add your people';
      sub = 'Tap + and paste your list.';
    }
    const dot = [
      (30.0, 16.0, 10.0, 10.0, Color(0xFFFFD23F), 0.35),
      (62.0, 40.0, 8.0, 14.0, Color(0xFF3EC1D3), -0.5),
      (20.0, 60.0, 12.0, 6.0, Colors.white, 0.7),
      (90.0, 12.0, 8.0, 8.0, Color(0xFF1E1B3A), 0.0),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 20, 0, 18),
      child: Transform.rotate(
        angle: -0.026,
        child: Container(
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(26)),
          child: Stack(children: [
            for (final (r, top, w, h, c, a) in dot)
              Positioned(
                right: r,
                top: top,
                child: Transform.rotate(
                  angle: a,
                  child: Container(width: w, height: h, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3))),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(small, style: t(12, w: FontWeight.w700, c: Colors.white70).copyWith(letterSpacing: 1)),
                const SizedBox(height: 6),
                Text(big, style: t(30, w: FontWeight.w800, c: Colors.white, h: 1.05)),
                const SizedBox(height: 6),
                Text(sub, style: t(14, c: Colors.white)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget row(e, now, index) {
    final d = e.daysUntil(now);
    final initials = e.name.split(' ').where((w) => w.isNotEmpty).take(2).map((w) => w.characters.first.toUpperCase()).join();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: _rows[index % _rows.length],
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ink, width: 2),
      ),
      child: Row(children: [
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: ink, width: 2)),
          child: Text(initials, style: t(14, w: FontWeight.w800)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(e.name, style: t(16, w: FontWeight.w700), overflow: TextOverflow.ellipsis),
            Text('${e.day} ${monthShort[e.month - 1]} · ${detail(e, now)}', style: t(12.5, c: muted)),
          ]),
        ),
        if (d == 0)
          Text('🎂', style: t(24))
        else
          Column(children: [
            Text('$d', style: t(22, w: FontWeight.w800, h: 1)),
            Text(d == 1 ? 'DAY' : 'DAYS', style: t(10, w: FontWeight.w700).copyWith(letterSpacing: 0.6)),
          ]),
      ]),
    );
  }

  @override
  (String, String) notification(e, age) => (
        age == null ? "It's ${e.name}'s birthday! 🎉" : '${e.name} just turned $age! 🎉',
        'Be the first to wish them. Midnight wishes hit different.',
      );
}

// ─── Midnight ───────────────────────────────────────────────────────────────

class Midnight extends BdayTheme {
  @override final id = 'midnight';
  @override final label = 'Midnight';
  @override final tagline = 'Quiet, glowing, built around the 12 AM moment';
  @override final brightness = Brightness.dark;
  @override final bg = const Color(0xFF0E0B2A);
  @override final ink = const Color(0xFFEDE8FF);
  @override final muted = const Color(0xFF8E86C7);
  @override final accent = const Color(0xFFFFC86B);
  @override final card = const Color(0xFF1B1640);
  @override final display = 'InstrumentSerif';
  @override final body = 'SpaceGrotesk';
  static const _orbs = [Color(0xFFFFC86B), Color(0xFFFF8FB1), Color(0xFF8FD3FF), Color(0xFFB4F0A8)];
  static const _days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

  @override
  Widget background() => CustomPaint(painter: _Stars(), size: Size.infinite);

  @override
  Widget header(today, next, now) {
    final serif = t(40, f: display, h: 1.05);
    final gold = serif.copyWith(color: accent, fontStyle: FontStyle.italic);
    final List<TextSpan> spans;
    if (today.isNotEmpty) {
      final age = today.first.ageIn(now.year);
      spans = [
        TextSpan(text: 'Tonight, ', style: serif),
        TextSpan(text: names(today), style: gold),
        TextSpan(text: today.length == 1 && age != null ? '\nturns $age.' : "'s\nday begins.", style: serif),
      ];
    } else if (next != null) {
      final d = next.daysUntil(now);
      spans = [
        TextSpan(text: 'Next, ', style: serif),
        TextSpan(text: next.name, style: gold),
        TextSpan(text: '\nin $d night${d == 1 ? '' : 's'}.', style: serif),
      ];
    } else {
      spans = [TextSpan(text: 'The sky is\n', style: serif), TextSpan(text: 'empty.', style: gold)];
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('TONIGHT · ${_days[now.weekday - 1]} ${now.day} ${monthShort[now.month - 1].toUpperCase()}',
          style: t(12, c: const Color(0xFF9C93D9)).copyWith(letterSpacing: 2.4)),
      const SizedBox(height: 6),
      Text.rich(TextSpan(children: spans)),
    ]);
  }

  @override
  Widget hero(today, next, now) {
    final (small, big, line) = today.isNotEmpty
        ? ('CANDLES LIT', 'Be the first\nto say it.', 'Their day started at midnight.')
        : next != null
            ? ('COUNTING DOWN', "We'll wake you\nat midnight.", 'A reminder at 12:00 AM on the day.')
            : ('NO STARS YET', 'Add the people\nyou love.', 'Tap + and paste your list.');
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 22),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A1F6B), Color(0xFF4B2A7A), Color(0xFF7A3B6E)],
          stops: [0, 0.6, 1],
        ),
      ),
      child: Stack(children: [
        Positioned(
          right: -30,
          top: -30,
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [accent.withValues(alpha: 0.55), accent.withValues(alpha: 0)], stops: const [0, 0.65]),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(small, style: t(11, c: accent).copyWith(letterSpacing: 2)),
            const SizedBox(height: 6),
            Text(big, style: t(32, f: display, h: 1.05)),
            const SizedBox(height: 6),
            Text(line, style: t(13, c: const Color(0xFFC9C1F2))),
          ]),
        ),
      ]),
    );
  }

  @override
  Widget row(e, now, index) {
    final d = e.daysUntil(now);
    final orb = _orbs[index % _orbs.length];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFF2A2560)))),
      child: Row(children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(shape: BoxShape.circle, color: orb, boxShadow: [BoxShadow(color: orb, blurRadius: 10)]),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(e.name, style: t(16, w: FontWeight.w500), overflow: TextOverflow.ellipsis),
            Text('${e.day} ${monthShort[e.month - 1]}${e.year == null ? '' : ' · ${e.ageIn(e.nextOn(now).year)}'}',
                style: t(12, c: muted)),
          ]),
        ),
        Text.rich(TextSpan(children: [
          if (d == 0)
            TextSpan(text: 'tonight', style: t(13, c: accent))
          else ...[
            TextSpan(text: '$d', style: t(18, w: FontWeight.w500)),
            TextSpan(text: d == 1 ? ' night' : ' nights', style: t(13, c: const Color(0xFFC9C1F2))),
          ],
        ])),
      ]),
    );
  }

  @override
  (String, String) notification(e, age) => (
        age == null ? "It's midnight. It's ${e.name}'s day." : "It's midnight. ${e.name} is $age now.",
        'You could be the very first to wish them.',
      );
}

// ─── Painters ───────────────────────────────────────────────────────────────

class _Dots extends CustomPainter {
  final Color c;
  _Dots(this.c);
  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()..color = c;
    for (double y = 7; y < s.height; y += 14) {
      for (double x = 7; x < s.width; x += 14) {
        canvas.drawCircle(Offset(x, y), 1, p);
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class _Dash extends CustomPainter {
  final Color c;
  _Dash(this.c);
  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()..color = c..strokeWidth = 1;
    for (double x = 0; x < s.width; x += 7) {
      canvas.drawLine(Offset(x, 0), Offset(min(x + 4, s.width), 0), p);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class _Stars extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final r = Random(7); // fixed seed: same sky every frame
    for (var i = 0; i < 70; i++) {
      canvas.drawCircle(
        Offset(r.nextDouble() * s.width, r.nextDouble() * s.height),
        r.nextDouble() * 1.1 + 0.4,
        Paint()..color = Colors.white.withValues(alpha: r.nextDouble() * 0.6 + 0.2),
      );
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
