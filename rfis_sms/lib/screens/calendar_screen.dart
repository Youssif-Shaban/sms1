import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../util.dart';
import '../widgets/common.dart';

/// Month / Week / Day / Agenda calendar fed by assignments (start and
/// deadline), exams, events and news, with the same filters as the portal.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  String _view = 'month';
  String _filter = 'all';
  late DateTime _focus;
  late DateTime _selected;

  static const int _minYear = 2016;
  static const int _maxYear = 2036;

  @override
  void initState() {
    super.initState();
    var t = today();
    if (t.year < _minYear) t = DateTime(_minYear, 1, 1);
    if (t.year > _maxYear) t = DateTime(_maxYear, 12, 31);
    _focus = t;
    _selected = t;
  }

  bool _matches(CalEvent e) {
    switch (_filter) {
      case 'assignments':
        return e.cat == CalCat.assignment;
      case 'homework':
        return e.cat == CalCat.homework;
      case 'exams':
        return e.cat == CalCat.exam;
      case 'events':
        return e.cat == CalCat.event;
      default:
        return true;
    }
  }

  void _move(DateTime focus, {DateTime? selected}) {
    if (focus.year < _minYear || focus.year > _maxYear) return;
    setState(() {
      _focus = focus;
      if (selected != null) _selected = selected;
    });
  }

  void _step(int dir) {
    if (_view == 'week') {
      final n = addDays(_focus, 7 * dir);
      _move(n, selected: n);
    } else if (_view == 'day') {
      final n = addDays(_focus, dir);
      _move(n, selected: n);
    } else {
      _move(DateTime(_focus.year, _focus.month + dir, 1));
    }
  }

  List<CalEvent> _on(DateTime day, List<CalEvent> events) =>
      events.where((e) => sameDay(e.date, day)).toList();

  // ------------------------------------------------------------------ header

  Widget _header(BuildContext context) {
    final months = context.app.isArabic ? kMonthsAr : kMonthsEn;
    Widget center;
    if (_view == 'week') {
      final start = addDays(dateOnly(_focus), -sundayIndex(_focus));
      final end = addDays(start, 6);
      center = Text(
        '${fmtDate(iso(start))} - ${fmtDate(iso(end))}',
        style: const TextStyle(fontWeight: FontWeight.bold),
      );
    } else if (_view == 'day') {
      final idx = sundayIndex(_focus);
      center = Text(
        '${context.tr(kDaysAr[idx], kDaysEn[idx])} ${fmtDate(iso(_focus))}',
        style: const TextStyle(fontWeight: FontWeight.bold),
      );
    } else {
      center = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButton<int>(
            value: _focus.month,
            underline: const SizedBox.shrink(),
            items: [
              for (var i = 1; i <= 12; i++)
                DropdownMenuItem<int>(value: i, child: Text(months[i - 1])),
            ],
            onChanged: (m) {
              if (m != null) _move(DateTime(_focus.year, m, 1));
            },
          ),
          const SizedBox(width: 8),
          DropdownButton<int>(
            value: _focus.year,
            underline: const SizedBox.shrink(),
            items: [
              for (var y = _minYear; y <= _maxYear; y++)
                DropdownMenuItem<int>(value: y, child: Text('$y')),
            ],
            onChanged: (y) {
              if (y != null) _move(DateTime(y, _focus.month, 1));
            },
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(prevIcon(context)),
            onPressed: () => _step(-1),
          ),
          Expanded(child: Center(child: center)),
          IconButton(
            icon: Icon(nextIcon(context)),
            onPressed: () => _step(1),
          ),
          TextButton(
            onPressed: () => _move(today(), selected: today()),
            child: Text(context.tr('اليوم', 'Today')),
          ),
        ],
      ),
    );
  }

  Widget _viewSelector(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: SizedBox(
        width: double.infinity,
        child: SegmentedButton<String>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment<String>(
              value: 'month',
              label: Text(context.tr('شهر', 'Month')),
            ),
            ButtonSegment<String>(
              value: 'week',
              label: Text(context.tr('أسبوع', 'Week')),
            ),
            ButtonSegment<String>(
              value: 'day',
              label: Text(context.tr('يوم', 'Day')),
            ),
            ButtonSegment<String>(
              value: 'agenda',
              label: Text(context.tr('أجندة', 'Agenda')),
            ),
          ],
          selected: <String>{_view},
          onSelectionChanged: (s) => setState(() => _view = s.first),
        ),
      ),
    );
  }

  Widget _filters(BuildContext context, List<CalEvent> monthEvents) {
    int count(CalCat? c) =>
        monthEvents.where((e) => c == null || e.cat == c).length;
    final items = <(String, String, String, int)>[
      ('all', 'كل العناصر', 'All items', count(null)),
      ('assignments', 'واجبات', 'Assignments', count(CalCat.assignment)),
      ('homework', 'واجب منزلي', 'Homework', count(CalCat.homework)),
      ('exams', 'اختبارات', 'Exams', count(CalCat.exam)),
      ('events', 'فعاليات وأخبار', 'Events & news', count(CalCat.event)),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          for (final it in items)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: ChoiceChip(
                label: Text('${context.tr(it.$2, it.$3)} (${it.$4})'),
                selected: _filter == it.$1,
                onSelected: (_) => setState(() => _filter = it.$1),
              ),
            ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------- views

  Widget _eventTile(BuildContext context, CalEvent e) {
    final color = e.deadline ? kDeadlineColor : e.cat.color;
    final String marker;
    if (e.marker == 'start') {
      marker = context.tr('تاريخ البداية', 'Start date');
    } else if (e.marker == 'end') {
      marker = context.tr('الموعد النهائي', 'Last deadline');
    } else {
      marker = context.tr(e.cat.ar, e.cat.en);
    }
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.app.go(e.route),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 5, color: color),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (e.subtitle.isNotEmpty)
                        Text(
                          e.subtitle,
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          StatusChip(label: marker, color: color),
                          const SizedBox(width: 8),
                          Text(
                            fmtDate(iso(e.date)),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _daySection(BuildContext context, DateTime day, List<CalEvent> events) {
    final idx = sundayIndex(day);
    final isToday = sameDay(day, today());
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isToday ? scheme.primaryContainer : Colors.black12,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${context.tr(kDaysAr[idx], kDaysEn[idx])} • ${fmtDate(iso(day))}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        if (events.isEmpty)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              context.tr('لا توجد عناصر', 'No items'),
              style: const TextStyle(color: Colors.grey),
            ),
          )
        else
          for (final e in events) _eventTile(context, e),
      ],
    );
  }

  Widget _dayCell(BuildContext context, int dayNum, int days, List<CalEvent> events) {
    if (dayNum < 1 || dayNum > days) return const SizedBox(height: 56);
    final scheme = Theme.of(context).colorScheme;
    final date = DateTime(_focus.year, _focus.month, dayNum);
    final dayEvents = _on(date, events);
    final selected = sameDay(date, _selected);
    final isToday = sameDay(date, today());
    final cats = dayEvents.map((e) => e.deadline ? null : e.cat).toSet();
    final dots = <Color>[];
    for (final c in cats) {
      dots.add(c == null ? kDeadlineColor : c.color);
      if (dots.length == 4) break;
    }
    return InkWell(
      onTap: () => setState(() => _selected = date),
      child: Container(
        height: 56,
        margin: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          color: selected ? scheme.primaryContainer : Colors.white,
          border: Border.all(
            color: isToday ? scheme.primary : Colors.black12,
            width: isToday ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('$dayNum'),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final c in dots)
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(color: c, shape: BoxShape.circle),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _monthView(BuildContext context, List<CalEvent> events) {
    final first = DateTime(_focus.year, _focus.month, 1);
    final lead = sundayIndex(first);
    final days = DateTime(_focus.year, _focus.month + 1, 0).day;
    final rows = ((lead + days) / 7).ceil();
    final shortDays = context.app.isArabic ? kDaysShortAr : kDaysShortEn;
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Row(
          children: [
            for (var i = 0; i < 7; i++)
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      shortDays[i],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        for (var r = 0; r < rows; r++)
          Row(
            children: [
              for (var c = 0; c < 7; c++)
                Expanded(
                  child: _dayCell(context, r * 7 + c - lead + 1, days, events),
                ),
            ],
          ),
        _daySection(context, _selected, _on(_selected, events)),
      ],
    );
  }

  Widget _weekView(BuildContext context, List<CalEvent> events) {
    final start = addDays(dateOnly(_focus), -sundayIndex(_focus));
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        for (var i = 0; i < 7; i++)
          _daySection(context, addDays(start, i), _on(addDays(start, i), events)),
      ],
    );
  }

  Widget _dayView(BuildContext context, List<CalEvent> events) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [_daySection(context, _focus, _on(_focus, events))],
    );
  }

  Widget _agendaView(BuildContext context, List<CalEvent> events) {
    final month = events
        .where((e) => e.date.year == _focus.year && e.date.month == _focus.month)
        .toList();
    if (month.isEmpty) {
      return EmptyState(message: context.tr('لا توجد عناصر', 'No items'));
    }
    final children = <Widget>[];
    DateTime? current;
    for (final e in month) {
      if (current == null || !sameDay(current, e.date)) {
        current = e.date;
        children.add(_agendaHeader(context, e.date));
      }
      children.add(_eventTile(context, e));
    }
    return ListView(padding: const EdgeInsets.all(12), children: children);
  }

  Widget _agendaHeader(BuildContext context, DateTime day) {
    final idx = sundayIndex(day);
    final isToday = sameDay(day, today());
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isToday ? scheme.primaryContainer : Colors.black12,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${context.tr(kDaysAr[idx], kDaysEn[idx])} • ${fmtDate(iso(day))}',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final all = app.calendarEvents();
    final events = all.where(_matches).toList();
    final monthEvents = all
        .where((e) => e.date.year == _focus.year && e.date.month == _focus.month)
        .toList();

    Widget body;
    switch (_view) {
      case 'week':
        body = _weekView(context, events);
        break;
      case 'day':
        body = _dayView(context, events);
        break;
      case 'agenda':
        body = _agendaView(context, events);
        break;
      default:
        body = _monthView(context, events);
    }

    return Column(
      children: [
        _header(context),
        _viewSelector(context),
        _filters(context, monthEvents),
        const SizedBox(height: 4),
        Expanded(child: body),
      ],
    );
  }
}
