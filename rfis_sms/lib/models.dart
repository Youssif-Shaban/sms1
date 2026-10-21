import 'package:flutter/material.dart';

/// A generic record: an id plus string fields. Every portal table
/// (students, classes, exams, ...) is a list of these.
class Rec {
  Rec(this.id, Map<String, String> source)
      : data = Map<String, String>.from(source);

  final String id;
  final Map<String, String> data;

  String operator [](String key) => data[key] ?? '';
}

enum FieldType { text, multiline, number, date, phone, email, choice, ref }

/// A choice option: stored [value], Arabic and English labels.
class Opt {
  const Opt(this.value, this.ar, this.en);

  final String value;
  final String ar;
  final String en;
}

class FieldDef {
  const FieldDef(
    this.key,
    this.ar,
    this.en, {
    this.type = FieldType.text,
    this.required = false,
    this.options = const <Opt>[],
    this.refTable = '',
    this.refKey = 'name',
  });

  final String key;
  final String ar;
  final String en;
  final FieldType type;
  final bool required;
  final List<Opt> options;
  final String refTable;
  final String refKey;
}

enum CalCat { assignment, homework, exam, event }

const Color kDeadlineColor = Color(0xFFD9534F);

extension CalCatX on CalCat {
  Color get color {
    switch (this) {
      case CalCat.assignment:
        return const Color(0xFF337AB7);
      case CalCat.homework:
        return const Color(0xFFEF8F00);
      case CalCat.exam:
        return const Color(0xFF7E57C2);
      case CalCat.event:
        return const Color(0xFF3E7C3E);
    }
  }

  String get ar {
    switch (this) {
      case CalCat.assignment:
        return 'واجبات';
      case CalCat.homework:
        return 'واجب منزلي';
      case CalCat.exam:
        return 'اختبارات';
      case CalCat.event:
        return 'فعاليات وأخبار';
    }
  }

  String get en {
    switch (this) {
      case CalCat.assignment:
        return 'Assignments';
      case CalCat.homework:
        return 'Homework';
      case CalCat.exam:
        return 'Exams';
      case CalCat.event:
        return 'Events & news';
    }
  }
}

/// One calendar entry, derived from assignments, exams, events and news.
/// [marker] is 'start', 'end' or 'single' (same idea as the portal feed).
class CalEvent {
  const CalEvent({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.cat,
    required this.marker,
    required this.deadline,
    required this.route,
  });

  final String id;
  final String title;
  final String subtitle;
  final DateTime date;
  final CalCat cat;
  final String marker;
  final bool deadline;
  final String route;
}

enum AttStatus { present, late, lateExcuse, absent, earlyDismissal }

extension AttStatusX on AttStatus {
  String get ar {
    switch (this) {
      case AttStatus.present:
        return 'حاضر';
      case AttStatus.late:
        return 'متأخر';
      case AttStatus.lateExcuse:
        return 'متأخر بعذر';
      case AttStatus.absent:
        return 'غائب';
      case AttStatus.earlyDismissal:
        return 'انصراف مبكر';
    }
  }

  String get en {
    switch (this) {
      case AttStatus.present:
        return 'Present';
      case AttStatus.late:
        return 'Late';
      case AttStatus.lateExcuse:
        return 'Late with excuse';
      case AttStatus.absent:
        return 'Absent';
      case AttStatus.earlyDismissal:
        return 'Early dismissal';
    }
  }

  Color get color {
    switch (this) {
      case AttStatus.present:
        return const Color(0xFF2E7D32);
      case AttStatus.late:
        return const Color(0xFFEF8F00);
      case AttStatus.lateExcuse:
        return const Color(0xFF0288D1);
      case AttStatus.absent:
        return const Color(0xFFD9534F);
      case AttStatus.earlyDismissal:
        return const Color(0xFF7E57C2);
    }
  }

  /// Everything except Absent counts as attended.
  bool get attended => this != AttStatus.absent;
}
