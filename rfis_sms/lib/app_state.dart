import 'package:flutter/material.dart';

import 'mock_data.dart';
import 'models.dart';
import 'util.dart';

/// All in-memory state of the simulated portal. Nothing here talks to a
/// server: every table is seeded by [seedData] and edited in memory.
class AppState extends ChangeNotifier {
  AppState() {
    seedData(this);
  }

  bool isArabic = true;
  bool loggedIn = false;
  String route = 'dashboard';
  String username = '';
  String password = 'demo123';

  final Map<String, String> profile = <String, String>{
    'name': 'Demo Admin',
    'gender': 'Male',
    'birthday': '1990-01-15',
    'mobile': '+966 50 000 0000',
    'address': 'Riyadh',
    'email': 'demo.admin@example.edu',
  };

  final Map<String, String> mailSettings = <String, String>{
    'senderName': 'RFIS',
    'mailDelivery': 'smtp',
    'smsProvider': 'provider_a',
  };

  final Map<String, List<Rec>> tables = <String, List<Rec>>{};

  /// key: "<className>|<yyyy-MM-dd>" -> studentId -> status
  final Map<String, Map<String, AttStatus>> attendance =
      <String, Map<String, AttStatus>>{};

  /// examId -> studentId -> mark
  final Map<String, Map<String, double>> marks =
      <String, Map<String, double>>{};

  /// assignmentId -> student ids who submitted
  final Map<String, Set<String>> submissions = <String, Set<String>>{};

  String pollQuestion = '';
  List<String> pollOptions = <String>[];
  List<int> pollVotes = <int>[];
  bool hasVoted = false;

  // Hand-off values used when one screen opens another with a preselection.
  String? marksheetExamId;
  String? marksheetStudentId;
  int marksheetTab = 0;

  int _counter = 1000;

  String newId() {
    _counter++;
    return 'r$_counter';
  }

  List<Rec> table(String name) => tables.putIfAbsent(name, () => <Rec>[]);

  Rec? find(String name, String id) {
    for (final r in table(name)) {
      if (r.id == id) return r;
    }
    return null;
  }

  Rec add(String name, Map<String, String> data) {
    final rec = Rec(newId(), data);
    table(name).add(rec);
    notifyListeners();
    return rec;
  }

  void update(String name, String id, Map<String, String> data) {
    final list = table(name);
    final i = list.indexWhere((r) => r.id == id);
    if (i < 0) return;
    final merged = <String, String>{...list[i].data, ...data};
    list[i] = Rec(id, merged);
    notifyListeners();
  }

  void remove(String name, String id) {
    table(name).removeWhere((r) => r.id == id);
    notifyListeners();
  }

  void touch() => notifyListeners();

  // ---------------------------------------------------------------- session

  void go(String newRoute) {
    route = newRoute;
    notifyListeners();
  }

  void setLanguage(bool arabic) {
    isArabic = arabic;
    notifyListeners();
  }

  /// Demo credentials: user "demo", password "demo123" (changeable in
  /// Account settings). Nothing else is accepted.
  bool login(String user, String pass) {
    if (user.trim().toLowerCase() == 'demo' && pass == password) {
      loggedIn = true;
      username = user.trim();
      route = 'dashboard';
      notifyListeners();
      return true;
    }
    return false;
  }

  void logout() {
    loggedIn = false;
    route = 'dashboard';
    notifyListeners();
  }

  // --------------------------------------------------------------- messages

  int get unreadMessages => table('messages')
      .where((m) => m['folder'] == 'inbox' && m['read'] == '0')
      .length;

  void markRead(String id) {
    final m = find('messages', id);
    if (m != null && m['read'] != '1') {
      update('messages', id, {'read': '1'});
    }
  }

  /// People a message can be addressed to.
  List<String> recipientNames() {
    final names = <String>{};
    for (final e in table('employees')) {
      names.add(e['name']);
    }
    for (final c in table('coordinators')) {
      names.add(c['name']);
    }
    for (final p in table('parents')) {
      names.add(p['name']);
    }
    names.removeWhere((n) => n.isEmpty);
    final list = names.toList()..sort();
    return list;
  }

  // ----------------------------------------------------------------- people

  List<Rec> studentsOfClass(String className) =>
      table('students').where((s) => s['class'] == className).toList();

  int get teacherCount =>
      table('employees').where((e) => e['role'] == 'Teacher').length;

  String nextStudentCode() {
    var maxNum = 1000;
    for (final s in table('students')) {
      final n = int.tryParse(s['code'].replaceAll(RegExp(r'[^0-9]'), ''));
      if (n != null && n > maxNum) maxNum = n;
    }
    return 'S-${maxNum + 1}';
  }

  /// Approves a pending admission: creates the student (and the parent when
  /// new) and marks the application as Approved. Returns the new student.
  Rec? approveAdmission(String id) {
    final a = find('admissions', id);
    if (a == null || a['status'] != 'Pending') return null;

    final parentName = a['parent'];
    if (parentName.isNotEmpty &&
        !table('parents').any((p) => p['name'] == parentName)) {
      table('parents').add(Rec(newId(), {
        'name': parentName,
        'phone': a['phone'],
        'email': a['email'],
      }));
    }

    final student = Rec(newId(), {
      'code': nextStudentCode(),
      'name': a['name'],
      'gender': a['gender'],
      'birthday': a['birthday'],
      'class': a['class'],
      'category': a['category'],
      'parent': parentName,
      'phone': a['phone'],
      'email': a['email'],
      'address': a['address'],
      'status': 'Active',
    });
    table('students').add(student);

    final list = table('admissions');
    final i = list.indexWhere((r) => r.id == id);
    list[i] = Rec(id, <String, String>{
      ...list[i].data,
      'status': 'Approved',
      'studentCode': student['code'],
    });
    notifyListeners();
    return student;
  }

  /// Moves the given students to [toClass] and writes a log line.
  void promote(List<String> studentIds, String fromClass, String toClass) {
    final students = table('students');
    for (final id in studentIds) {
      final i = students.indexWhere((s) => s.id == id);
      if (i >= 0) {
        students[i] = Rec(id, <String, String>{
          ...students[i].data,
          'class': toClass,
        });
      }
    }
    table('promotionLog').add(Rec(newId(), {
      'date': iso(today()),
      'time': nowTime(),
      'from': fromClass,
      'to': toClass,
      'count': '${studentIds.length}',
      'by': profile['name'] ?? '',
    }));
    notifyListeners();
  }

  // ------------------------------------------------------------- attendance

  String attendanceKey(String className, String dateIso) =>
      '$className|$dateIso';

  Map<String, AttStatus>? attendanceFor(String className, String dateIso) =>
      attendance[attendanceKey(className, dateIso)];

  void saveAttendance(
    String className,
    String dateIso,
    Map<String, AttStatus> data,
  ) {
    attendance[attendanceKey(className, dateIso)] =
        Map<String, AttStatus>.from(data);
    notifyListeners();
  }

  // ------------------------------------------------------------------ marks

  void saveMarks(String examId, Map<String, double> data) {
    marks[examId] = Map<String, double>.from(data);
    notifyListeners();
  }

  // ------------------------------------------------------------ assignments

  int submittedCount(String assignmentId) =>
      (submissions[assignmentId] ?? <String>{}).length;

  void toggleSubmission(String assignmentId, String studentId) {
    final set = submissions.putIfAbsent(assignmentId, () => <String>{});
    if (!set.add(studentId)) set.remove(studentId);
    notifyListeners();
  }

  // ------------------------------------------------------------------- poll

  void vote(int index) {
    if (hasVoted || index < 0 || index >= pollVotes.length) return;
    pollVotes[index] += 1;
    hasVoted = true;
    notifyListeners();
  }

  // --------------------------------------------------------------- calendar

  /// Builds the calendar feed from assignments (start + deadline markers),
  /// exams, events and news, like the portal's /calender endpoint.
  List<CalEvent> calendarEvents() {
    final out = <CalEvent>[];

    for (final a in table('assignments')) {
      final cat =
          a['type'] == 'Homework' ? CalCat.homework : CalCat.assignment;
      final sub = '${a['class']} • ${a['subject']}';
      final s = parseIso(a['start']);
      final e = parseIso(a['end']);
      if (s != null) {
        out.add(CalEvent(
          id: '${a.id}-start',
          title: a['title'],
          subtitle: sub,
          date: s,
          cat: cat,
          marker: 'start',
          deadline: false,
          route: 'onlineAssignments',
        ));
      }
      if (e != null) {
        out.add(CalEvent(
          id: '${a.id}-end',
          title: a['title'],
          subtitle: sub,
          date: e,
          cat: cat,
          marker: 'end',
          deadline: true,
          route: 'onlineAssignments',
        ));
      }
    }

    for (final x in table('exams')) {
      final d = parseIso(x['date']);
      if (d == null) continue;
      out.add(CalEvent(
        id: '${x.id}-exam',
        title: x['name'],
        subtitle: '${x['class']} • ${x['subject']}',
        date: d,
        cat: CalCat.exam,
        marker: 'single',
        deadline: false,
        route: 'examsList',
      ));
    }

    for (final ev in table('events')) {
      final d = parseIso(ev['date']);
      if (d == null) continue;
      out.add(CalEvent(
        id: '${ev.id}-event',
        title: ev['title'],
        subtitle: ev['place'],
        date: d,
        cat: CalCat.event,
        marker: 'single',
        deadline: false,
        route: 'dashboard',
      ));
    }

    for (final n in table('news')) {
      final d = parseIso(n['date']);
      if (d == null) continue;
      out.add(CalEvent(
        id: '${n.id}-news',
        title: n['title'],
        subtitle: '',
        date: d,
        cat: CalCat.event,
        marker: 'single',
        deadline: false,
        route: 'dashboard',
      ));
    }

    out.sort((a, b) => a.date.compareTo(b.date));
    return out;
  }
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({
    Key? key,
    required AppState state,
    required Widget child,
  }) : super(key: key, notifier: state, child: child);

  /// Use inside build(): rebuilds the widget when state changes.
  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found in the widget tree');
    return scope!.notifier!;
  }

  /// Use inside initState(): reads the state without subscribing.
  static AppState read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found in the widget tree');
    return scope!.notifier!;
  }
}

extension AppContext on BuildContext {
  AppState get app => AppScope.of(this);

  /// Picks the Arabic or English text for the current language.
  String tr(String ar, String en) => app.isArabic ? ar : en;
}
