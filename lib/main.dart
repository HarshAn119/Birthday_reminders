import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'entry.dart';
import 'reminders.dart';
import 'themes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final state = AppState(await SharedPreferences.getInstance());
  runApp(App(state));
  await initReminders();
  await reschedule(state.entries, state.theme); // refresh ages and the rolling batch on every launch
}

class AppState extends ChangeNotifier {
  final SharedPreferences prefs;
  List<Entry> entries;
  BdayTheme theme;

  AppState(this.prefs)
      : entries = (jsonDecode(prefs.getString('entries') ?? '[]') as List).map((j) => Entry.fromJson(j)).toList(),
        theme = themeById(prefs.getString('theme'));

  Future<void> _commit() async {
    notifyListeners();
    await prefs.setString('entries', jsonEncode(entries));
    await reschedule(entries, theme);
  }

  /// Returns how many were new (exact duplicates are skipped).
  int addAll(Iterable<Entry> es) {
    var n = 0;
    for (final e in es) {
      if (entries.any((x) => x.name == e.name && x.day == e.day && x.month == e.month)) continue;
      entries.add(e);
      n++;
    }
    _commit();
    return n;
  }

  void replace(Entry old, Entry e) {
    entries[entries.indexOf(old)] = e;
    _commit();
  }

  void remove(Entry e) {
    entries.remove(e);
    _commit();
  }

  void setTheme(BdayTheme t) {
    theme = t;
    prefs.setString('theme', t.id);
    _commit();
  }
}

class App extends StatelessWidget {
  final AppState state;
  const App(this.state, {super.key});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: state,
        builder: (context, _) {
          final th = state.theme;
          return MaterialApp(
            title: 'Birthdays',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: th.accent, brightness: th.brightness, surface: th.bg),
              scaffoldBackgroundColor: th.bg,
              fontFamily: th.body,
            ),
            home: Home(state),
          );
        },
      );
}

// ─── Home ───────────────────────────────────────────────────────────────────

class Home extends StatelessWidget {
  final AppState state;
  const Home(this.state, {super.key});

  @override
  Widget build(BuildContext context) {
    final th = state.theme;
    final now = DateTime.now();
    final sorted = [...state.entries]
      ..sort((a, b) => a.daysUntil(now).compareTo(b.daysUntil(now)) * 1000 + a.name.compareTo(b.name).sign);
    final today = sorted.where((e) => e.daysUntil(now) == 0).toList();
    final next = sorted.where((e) => e.daysUntil(now) > 0).firstOrNull;

    return Scaffold(
      body: Stack(children: [
        Positioned.fill(child: th.background()),
        SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: th.header(today, next, now)),
                _RoundButton(
                  icon: Icons.palette_outlined,
                  label: 'Change theme',
                  th: th,
                  filled: false,
                  onTap: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: th.bg,
                    showDragHandle: true,
                    builder: (_) => ThemePicker(state),
                  ),
                ),
                const SizedBox(width: 8),
                _RoundButton(
                  icon: Icons.add,
                  label: 'Add dates',
                  th: th,
                  filled: true,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddScreen(state))),
                ),
              ]),
              th.hero(today, next, now),
              for (final (i, e) in sorted.indexed)
                InkWell(
                  onTap: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: th.bg,
                    showDragHandle: true,
                    builder: (_) => EditSheet(state, e),
                  ),
                  child: th.row(e, now, i),
                ),
            ],
          ),
        ),
      ]),
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final BdayTheme th;
  final bool filled;
  final VoidCallback onTap;
  const _RoundButton({required this.icon, required this.label, required this.th, required this.filled, required this.onTap});

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label,
        child: Material(
          color: filled ? th.ink : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: filled ? BorderSide.none : BorderSide(color: th.ink.withValues(alpha: 0.3), width: 1.5),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: SizedBox(width: 44, height: 44, child: Icon(icon, color: filled ? th.bg : th.ink, size: filled ? 26 : 22)),
          ),
        ),
      );
}

// ─── Add / paste ────────────────────────────────────────────────────────────

class AddScreen extends StatefulWidget {
  final AppState state;
  const AddScreen(this.state, {super.key});
  @override
  State<AddScreen> createState() => _AddScreenState();
}

class _AddScreenState extends State<AddScreen> {
  final _text = TextEditingController();
  List<ParsedLine> _parsed = [];

  @override
  Widget build(BuildContext context) {
    final th = widget.state.theme;
    final ok = _parsed.where((p) => p.entry != null).map((p) => p.entry!).toList();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: th.bg,
        foregroundColor: th.ink,
        title: Text('Add dates', style: th.t(22, f: th.display, w: FontWeight.w600)),
      ),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Text('Type one, or paste your whole Google Keep note.', style: th.t(15, c: th.muted)),
        const SizedBox(height: 12),
        TextField(
          controller: _text,
          autofocus: true,
          minLines: 6,
          maxLines: null,
          style: th.t(15),
          onChanged: (s) => setState(() => _parsed = parseLines(s)),
          decoration: InputDecoration(
            hintText: 'Rahul - 10 Nov 1996\nPriya Sharma: 14/11\nMom & Dad anniversary 2 Dec',
            hintStyle: th.t(15, c: th.muted.withValues(alpha: 0.6)),
            filled: true,
            fillColor: th.card,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: th.muted.withValues(alpha: 0.4))),
          ),
        ),
        const SizedBox(height: 8),
        Text('One per line. Day comes first: 02/09 is 2 September.', style: th.t(12.5, c: th.muted)),
        if (_parsed.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text('Preview', style: th.t(14, w: FontWeight.w600, c: th.muted)),
          const SizedBox(height: 6),
          for (final p in _parsed) _PreviewLine(p, th),
        ],
        const SizedBox(height: 20),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: th.ink,
            foregroundColor: th.bg,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: ok.isEmpty
              ? null
              : () {
                  final n = widget.state.addAll(ok);
                  final skipped = _parsed.length - ok.length;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Saved $n ${n == 1 ? 'date' : 'dates'}'
                        '${ok.length > n ? ' · ${ok.length - n} already there' : ''}'
                        '${skipped > 0 ? ' · $skipped need fixing' : ''}'),
                  ));
                  if (skipped == 0) {
                    Navigator.pop(context);
                  } else {
                    // keep only the lines that need fixing in the box
                    _text.text = _parsed.where((p) => p.entry == null).map((p) => p.line).join('\n');
                    setState(() => _parsed = parseLines(_text.text));
                  }
                },
          child: Text(ok.isEmpty ? 'Save' : 'Save ${ok.length} ${ok.length == 1 ? 'date' : 'dates'}',
              style: th.t(16, w: FontWeight.w600, c: th.bg)),
        ),
      ]),
    );
  }
}

class _PreviewLine extends StatelessWidget {
  final ParsedLine p;
  final BdayTheme th;
  const _PreviewLine(this.p, this.th);

  @override
  Widget build(BuildContext context) {
    final e = p.entry;
    if (e != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Icon(Icons.check, size: 18, color: th.brightness == Brightness.dark ? const Color(0xFFB4F0A8) : const Color(0xFF3B6D11)),
          const SizedBox(width: 8),
          Expanded(
            child: Text('${e.name} · ${e.day} ${monthShort[e.month - 1]}${e.year == null ? '' : ' ${e.year}'}', style: th.t(14)),
          ),
        ]),
      );
    }
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: const Color(0xFFFAEEDA), borderRadius: BorderRadius.circular(8)),
      child: Row(children: [
        const Icon(Icons.warning_amber_rounded, size: 18, color: Color(0xFF854F0B)),
        const SizedBox(width: 8),
        Expanded(child: Text('"${p.line}": ${p.error}', style: th.t(13.5, c: const Color(0xFF633806)))),
      ]),
    );
  }
}

// ─── Edit ───────────────────────────────────────────────────────────────────

class EditSheet extends StatefulWidget {
  final AppState state;
  final Entry entry;
  const EditSheet(this.state, this.entry, {super.key});
  @override
  State<EditSheet> createState() => _EditSheetState();
}

class _EditSheetState extends State<EditSheet> {
  late final _text = TextEditingController(
      text: '${widget.entry.name} ${widget.entry.day} ${monthLong[widget.entry.month - 1]}'
          '${widget.entry.year == null ? '' : ' ${widget.entry.year}'}');
  late ParsedLine _p = parseLine(_text.text, now: DateTime.now());

  @override
  Widget build(BuildContext context) {
    final th = widget.state.theme;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Edit', style: th.t(22, f: th.display, w: FontWeight.w600)),
        const SizedBox(height: 12),
        TextField(
          controller: _text,
          style: th.t(16),
          onChanged: (s) => setState(() => _p = parseLine(s, now: DateTime.now())),
          decoration: InputDecoration(
            filled: true,
            fillColor: th.card,
            errorText: _p.error,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),
        Row(children: [
          TextButton.icon(
            onPressed: () {
              widget.state.remove(widget.entry);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Deleted ${widget.entry.name}'),
                action: SnackBarAction(label: 'Undo', onPressed: () => widget.state.addAll([widget.entry])),
              ));
            },
            icon: const Icon(Icons.delete_outline, color: Color(0xFFE24B4A)),
            label: Text('Delete', style: th.t(15, c: const Color(0xFFE24B4A))),
          ),
          const Spacer(),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: th.ink, foregroundColor: th.bg),
            onPressed: _p.entry == null
                ? null
                : () {
                    widget.state.replace(widget.entry, _p.entry!);
                    Navigator.pop(context);
                  },
            child: Text('Save', style: th.t(15, w: FontWeight.w600, c: th.bg)),
          ),
        ]),
      ]),
    );
  }
}

// ─── Theme picker ───────────────────────────────────────────────────────────

class ThemePicker extends StatelessWidget {
  final AppState state;
  const ThemePicker(this.state, {super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final sample = Entry('Priya Sharma', now.add(const Duration(days: 4)).day, now.add(const Duration(days: 4)).month, now.year - 26);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          for (final t in themes)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Semantics(
                selected: t.id == state.theme.id,
                button: true,
                child: GestureDetector(
                  onTap: () {
                    state.setTheme(t);
                    Navigator.pop(context);
                  },
                  child: Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: t.bg,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: t.id == state.theme.id ? t.accent : t.ink.withValues(alpha: 0.15), width: t.id == state.theme.id ? 3 : 1),
                    ),
                    child: Stack(children: [
                      Positioned.fill(child: t.background()),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Text(t.label, style: t.t(20, f: t.display, w: FontWeight.w600)),
                            const Spacer(),
                            if (t.id == state.theme.id) Icon(Icons.check_circle, color: t.accent),
                          ]),
                          Text(t.tagline, style: t.t(13, c: t.muted)),
                          const SizedBox(height: 6),
                          IgnorePointer(child: t.row(sample, now, 0)),
                        ]),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
        ]),
      ),
    );
  }
}
