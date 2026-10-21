import 'dart:math';

import 'app_state.dart';
import 'models.dart';
import 'util.dart';

/// Fills [s] with fictional sample data. All names, phones and e-mails are
/// invented; nothing here comes from the real school portal.
void seedData(AppState s) {
  final base = today();
  String d(int offset) => iso(addDays(base, offset));

  Rec add(String table, Map<String, String> data) {
    final r = Rec(s.newId(), data);
    s.table(table).add(r);
    return r;
  }

  const classNames = <String>[
    'Grade 4-A',
    'Grade 5-A',
    'Grade 6-A',
    'Grade 7-A',
    'Grade 8-A',
    'Grade 9-A',
  ];

  const subjectNames = <String>[
    'Mathematics',
    'English',
    'Science',
    'Social Studies',
    'Arabic',
    'Computer Science',
    'Islamic Studies',
    'Physical Education',
  ];
  const subjectCodes = <String>[
    'MATH',
    'ENG',
    'SCI',
    'SOC',
    'ARB',
    'CS',
    'ISL',
    'PE',
  ];

  // ---------------------------------------------------------------- employees
  final staff = <(String, String, String)>[
    ('Ahmed Al-Salem', 'Male', 'Teacher'),
    ('Laila Nasser', 'Female', 'Teacher'),
    ('Omar Khalid', 'Male', 'Teacher'),
    ('Huda Ibrahim', 'Female', 'Teacher'),
    ('Sara Al-Qahtani', 'Female', 'Teacher'),
    ('Khaled Mansour', 'Male', 'Teacher'),
    ('Mona Fahad', 'Female', 'Teacher'),
    ('Tariq Saeed', 'Male', 'Teacher'),
    ('Nadia Hakim', 'Female', 'Administrator'),
    ('Basel Karam', 'Male', 'Librarian'),
  ];
  for (var i = 0; i < staff.length; i++) {
    final p = staff[i];
    final emailName = p.$1.toLowerCase().replaceAll(' ', '.').replaceAll('-', '');
    add('employees', {
      'code': 'E-${101 + i}',
      'name': p.$1,
      'gender': p.$2,
      'role': p.$3,
      'email': '$emailName@example.edu',
      'phone': '+966 50 000 ${1000 + i}',
      'joined': d(-400 - i * 30),
    });
  }

  // ----------------------------------------------------------------- subjects
  for (var i = 0; i < subjectNames.length; i++) {
    add('subjects', {
      'name': subjectNames[i],
      'code': subjectCodes[i],
      'teacher': staff[i].$1,
    });
  }

  // ------------------------------------------------------------------ classes
  for (var i = 0; i < classNames.length; i++) {
    add('classes', {
      'name': classNames[i],
      'teacher': staff[i].$1,
      'room': 'Room ${101 + i}',
      'description': '',
    });
  }

  // --------------------------------------------------------------- categories
  add('categories', {
    'name': 'Regular',
    'description': 'Standard tuition category',
  });
  add('categories', {
    'name': 'Scholarship',
    'description': 'Students on a merit scholarship',
  });
  add('categories', {
    'name': 'Staff Child',
    'description': 'Children of school staff',
  });
  add('categories', {
    'name': 'Sibling Discount',
    'description': 'Families with more than one child enrolled',
  });

  // ----------------------------------------------------------------- students
  const studentNames = <String>[
    'Yazan Al-Harbi',
    'Reem Al-Otaibi',
    'Faisal Mansour',
    'Lama Al-Ghamdi',
    'Nawaf Hussein',
    'Dana Al-Sudairi',
    'Salman Al-Dosari',
    'Maya Khalil',
    'Rakan Al-Shehri',
    'Joud Al-Mutairi',
    'Abdullah Tamimi',
    'Nora Al-Zahrani',
    'Turki Al-Anazi',
    'Shahd Al-Subaie',
    'Mazen Bakr',
    'Ghada Al-Rashed',
    'Hamad Al-Qahtani',
    'Ayah Saleh',
  ];
  for (var i = 0; i < studentNames.length; i++) {
    final name = studentNames[i];
    final family = name.split(' ').last;
    final grade = 4 + i ~/ 3;
    final year = 2026 - 6 - grade;
    final month = 1 + (i * 5) % 12;
    final day = 1 + (i * 7) % 27;
    final parentName = '$family Family';
    add('parents', {
      'name': parentName,
      'phone': '+966 55 000 ${1000 + i}',
      'email': 'parent${i + 1}@example.edu',
    });
    add('students', {
      'code': 'S-${1001 + i}',
      'name': name,
      'gender': i.isEven ? 'Male' : 'Female',
      'birthday': iso(DateTime(year, month, day)),
      'class': classNames[i ~/ 3],
      'category': i == 7
          ? 'Staff Child'
          : (i % 5 == 0 ? 'Scholarship' : 'Regular'),
      'parent': parentName,
      'phone': '+966 55 000 ${1000 + i}',
      'email': 'parent${i + 1}@example.edu',
      'address': 'Riyadh - District ${1 + i % 6}',
      'status': 'Active',
    });
  }

  // ------------------------------------------------------------- coordinators
  add('coordinators', {
    'name': 'Rania Al-Amri',
    'section': 'Primary',
    'email': 'rania.alamri@example.edu',
    'phone': '+966 50 000 2001',
    'status': 'Active',
  });
  add('coordinators', {
    'name': 'Fahad Al-Nasser',
    'section': 'Middle',
    'email': 'fahad.alnasser@example.edu',
    'phone': '+966 50 000 2002',
    'status': 'Active',
  });
  add('coordinators', {
    'name': 'Salma Youssef',
    'section': 'Secondary',
    'email': 'salma.youssef@example.edu',
    'phone': '+966 50 000 2003',
    'status': 'Active',
  });
  add('coordinators', {
    'name': 'Ibrahim Darwish',
    'section': 'Activities',
    'email': 'ibrahim.darwish@example.edu',
    'phone': '+966 50 000 2004',
    'status': 'Inactive',
  });

  // ---------------------------------------------------------------- materials
  final materials = <(String, String, String, String, int, String)>[
    ('Map skills slides', 'Social Studies', 'Grade 7-A', 'PPTX', -1,
        'Slides covering the main map-reading tools.'),
    ('Fractions summary sheet', 'Mathematics', 'Grade 4-A', 'PDF', -2,
        'One-page summary of fraction rules.'),
    ('Reading comprehension pack', 'English', 'Grade 5-A', 'DOCX', -3,
        'Short texts with comprehension questions.'),
    ('Plant life cycle video', 'Science', 'Grade 6-A', 'Video', -4,
        'Animated overview of the plant life cycle.'),
    ('Algebra practice bank', 'Mathematics', 'Grade 8-A', 'XLSX', -5,
        'Practice problems grouped by difficulty.'),
    ('Arabic grammar chart', 'Arabic', 'Grade 6-A', 'PDF', -6,
        'Chart of verb and noun patterns.'),
    ('Intro to loops', 'Computer Science', 'Grade 9-A', 'PPTX', -7,
        'Introductory slides about loops.'),
    ('Online dictionary link', 'English', 'Grade 9-A', 'Link', -8,
        'Recommended dictionary website.'),
  ];
  for (final m in materials) {
    add('materials', {
      'title': m.$1,
      'subject': m.$2,
      'class': m.$3,
      'fileType': m.$4,
      'date': d(m.$5),
      'description': m.$6,
      'sharedBy': 'Demo Admin',
    });
  }

  // -------------------------------------------------------------------- media
  final media = <(String, String, String, int, String)>[
    ('Sports day highlights', 'Video', 'Sports', -20, 'Short clip from last sports day.'),
    ('Science fair gallery', 'Image', 'Science fair', -15, 'Photos of student projects.'),
    ('Morning assembly audio', 'Audio', 'Assembly', -12, 'Recorded assembly speech.'),
    ('Library tour', 'Video', 'Library', -9, 'Introductory tour for new students.'),
    ('Term handbook', 'Document', 'Handbooks', -30, 'Student handbook PDF.'),
    ('Art exhibition', 'Image', 'Arts', -5, 'Artwork from Grade 6 and 7.'),
  ];
  for (final m in media) {
    add('media', {
      'title': m.$1,
      'type': m.$2,
      'album': m.$3,
      'date': d(m.$4),
      'description': m.$5,
    });
  }

  // -------------------------------------------------------------------- exams
  final exams = <(String, String, String, int, int, int, String)>[
    ('Unit 3 Test', 'Grade 5-A', 'Mathematics', -10, 50, 40, 'Online'),
    ('Midterm Exam', 'Grade 6-A', 'Science', -7, 100, 60, 'Written'),
    ('Reading Quiz', 'Grade 7-A', 'English', -3, 20, 20, 'Online'),
    ('Midterm Exam', 'Grade 8-A', 'Mathematics', 4, 100, 90, 'Written'),
    ('Geography Quiz', 'Grade 9-A', 'Social Studies', 6, 30, 25, 'Online'),
    ('Unit 4 Test', 'Grade 4-A', 'Mathematics', 9, 50, 40, 'Online'),
  ];
  final examRecs = <Rec>[];
  for (final e in exams) {
    examRecs.add(add('exams', {
      'name': e.$1,
      'class': e.$2,
      'subject': e.$3,
      'date': d(e.$4),
      'maxMark': '${e.$5}',
      'duration': '${e.$6}',
      'type': e.$7,
      'description': '',
    }));
  }

  // Questions for every online exam (same small generic bank).
  const bank = <(String, String, String, String, String, String)>[
    ('Which number is prime?', '9', '11', '15', '21', 'B'),
    ('What is 7 x 8?', '54', '56', '58', '64', 'B'),
    ('Which planet is known as the Red Planet?', 'Venus', 'Mars', 'Jupiter', 'Saturn', 'B'),
    ('Choose the correct plural of "child".', 'childs', 'childes', 'children', 'childrens', 'C'),
  ];
  for (final ex in examRecs) {
    if (ex['type'] != 'Online') continue;
    for (final q in bank) {
      add('questions', {
        'examId': ex.id,
        'text': q.$1,
        'a': q.$2,
        'b': q.$3,
        'c': q.$4,
        'd': q.$5,
        'correct': q.$6,
      });
    }
  }

  final rnd = Random(7);

  // Marks for exams that already took place.
  for (final ex in examRecs) {
    final exDate = parseIso(ex['date']);
    if (exDate == null || !exDate.isBefore(base)) continue;
    final max = double.parse(ex['maxMark']);
    final marks = <String, double>{};
    for (final st in s.studentsOfClass(ex['class'])) {
      marks[st.id] = (max * (0.45 + rnd.nextDouble() * 0.55)).roundToDouble();
    }
    s.marks[ex.id] = marks;
  }

  // -------------------------------------------------------------- assignments
  final assignments = <(String, String, String, String, int, int, String)>[
    ('Fractions practice set', 'Grade 4-A', 'Mathematics', 'Assignment', -6, 2, 'Complete pages 12 to 14.'),
    ('Reading log week 6', 'Grade 5-A', 'English', 'Homework', -3, 1, 'Record 20 minutes of reading daily.'),
    ('Plant life cycle worksheet', 'Grade 6-A', 'Science', 'Assignment', -5, 3, 'Label the diagram and answer the questions.'),
    ('Map skills worksheet', 'Grade 7-A', 'Social Studies', 'Homework', -2, 4, 'Use the atlas to answer the questions.'),
    ('Linear equations set', 'Grade 8-A', 'Mathematics', 'Assignment', -7, -1, 'Solve problems 1 to 20.'),
    ('Vocabulary list 5', 'Grade 9-A', 'English', 'Assignment', 0, 5, 'Write a sentence for each word.'),
    ('Arabic dictation', 'Grade 4-A', 'Arabic', 'Homework', -1, 2, 'Practice the dictation words.'),
    ('Coding basics quiz', 'Grade 7-A', 'Computer Science', 'Assignment', 1, 7, 'Online quiz about variables.'),
    ('Photosynthesis summary', 'Grade 6-A', 'Science', 'Homework', -4, 0, 'Summarise in 10 lines.'),
    ('Ratios worksheet', 'Grade 8-A', 'Mathematics', 'Homework', 2, 9, 'Worksheet on equivalent ratios.'),
  ];
  for (final a in assignments) {
    final rec = add('assignments', {
      'title': a.$1,
      'class': a.$2,
      'subject': a.$3,
      'type': a.$4,
      'start': d(a.$5),
      'end': d(a.$6),
      'description': a.$7,
      'attachment': '',
    });
    final done = <String>{};
    for (final st in s.studentsOfClass(a.$2)) {
      if (rnd.nextDouble() < 0.5) done.add(st.id);
    }
    s.submissions[rec.id] = done;
  }

  // ------------------------------------------------------------ events & news
  add('events', {
    'title': 'Parent-teacher meeting',
    'place': 'School hall',
    'date': d(8),
    'description': 'Meet the class teachers.',
  });
  add('events', {
    'title': 'Science fair',
    'place': 'Main yard',
    'date': d(14),
    'description': 'Student projects exhibition.',
  });
  add('events', {
    'title': 'Sports day',
    'place': 'Sports field',
    'date': d(20),
    'description': 'Inter-class sports competition.',
  });
  add('events', {
    'title': 'Reading week',
    'place': 'Library',
    'date': d(3),
    'description': 'Book fair and reading challenges.',
  });

  add('news', {
    'title': 'Term calendar published',
    'content': 'The calendar for this term is now available.',
    'date': d(-2),
  });
  add('news', {
    'title': 'New learning resources available',
    'content': 'Teachers have shared new study material for all grades.',
    'date': d(-1),
  });
  add('news', {
    'title': 'Please update contact details',
    'content': 'Parents should confirm their phone numbers and e-mail addresses.',
    'date': d(0),
  });

  // ---------------------------------------------------------------- templates
  add('templates', {
    'title': 'Absence notice',
    'type': 'SMS',
    'content': 'Dear parent, {student} of {class} was absent on {date}. - {school}',
  });
  add('templates', {
    'title': 'Assignment reminder',
    'type': 'SMS',
    'content': 'Reminder: {student} has an assignment due soon. - {school}',
  });
  add('templates', {
    'title': 'Parent meeting invitation',
    'type': 'Mail',
    'content':
        'Dear parent of {student},\n\nYou are invited to the parent-teacher meeting for {class} on {date}.\n\nKind regards,\n{school}',
  });
  add('templates', {
    'title': 'Exam schedule',
    'type': 'Mail',
    'content':
        'Dear {student},\n\nThe exam schedule for {class} has been published.\n\n{school}',
  });

  // ----------------------------------------------------------------- messages
  final messages = <(String, String, String, String, int, String, String, String)>[
    ('Rania Al-Amri', 'Demo Admin', 'Primary timetable changes',
        'Please review the updated primary timetable before Sunday.', -1, '09:15', 'inbox', '0'),
    ('Ahmed Al-Salem', 'Demo Admin', 'Math exam hall',
        'Can we move the Grade 8 midterm to the main hall?', -1, '12:40', 'inbox', '0'),
    ('Nadia Hakim', 'Demo Admin', 'Fee statements',
        'The fee statements for this month are ready for approval.', -2, '10:05', 'inbox', '1'),
    ('Salma Youssef', 'Demo Admin', 'Secondary activities',
        'Proposed activities list for the secondary section attached.', -3, '14:20', 'inbox', '1'),
    ('Laila Nasser', 'Demo Admin', 'English reading week',
        'Reading week plan is ready. Library booking needed.', -4, '08:30', 'inbox', '0'),
    ('Demo Admin', 'Rania Al-Amri', 'Re: Primary timetable changes',
        'Thank you, I will review it today.', -1, '09:40', 'sent', '1'),
    ('Demo Admin', 'Nadia Hakim', 'Fee statement approval',
        'Approved. Please send them out.', -2, '11:00', 'sent', '1'),
  ];
  for (final m in messages) {
    add('messages', {
      'from': m.$1,
      'to': m.$2,
      'subject': m.$3,
      'body': m.$4,
      'date': d(m.$5),
      'time': m.$6,
      'folder': m.$7,
      'read': m.$8,
    });
  }

  // ------------------------------------------------------------ notifications
  add('notifications', {
    'title': 'Early dismissal tomorrow',
    'message': 'School will end at 11:30 tomorrow for staff training.',
    'audience': 'All',
    'recipients': '${studentNames.length + staff.length + studentNames.length}',
    'date': d(-3),
    'time': '13:00',
    'sentBy': 'Demo Admin',
  });
  add('notifications', {
    'title': 'Exam week starts Sunday',
    'message': 'Please review the exam schedule in the calendar.',
    'audience': 'Students',
    'recipients': '${studentNames.length}',
    'date': d(-2),
    'time': '09:30',
    'sentBy': 'Demo Admin',
  });
  add('notifications', {
    'title': 'Staff meeting',
    'message': 'Staff meeting at 2 pm in the library.',
    'audience': 'Teachers',
    'recipients': '8',
    'date': d(-1),
    'time': '10:10',
    'sentBy': 'Demo Admin',
  });

  // ----------------------------------------------------------------- payments
  final payments = <(String, String, int, int, String)>[
    ('Term 1 tuition', 'Paid', -60, -45, '4500'),
    ('Transport fee', 'Pending', -5, 10, '900'),
    ('Activities fee', 'Overdue', -40, -10, '250'),
    ('Books pack', 'Paid', -70, -50, '600'),
  ];
  for (final p in payments) {
    add('payments', {
      'title': p.$1,
      'status': p.$2,
      'date': d(p.$3),
      'due': d(p.$4),
      'amount': p.$5,
    });
  }

  // ----------------------------------------------------------------- sent mail
  add('sentMail', {
    'type': 'SMS',
    'audience': 'parents',
    'class': 'Grade 5-A',
    'title': 'Absence notice',
    'content': 'Dear parent, your child was absent yesterday. - RFIS',
    'date': d(-2),
    'time': '08:45',
    'recipients': '3',
    'segments': '1',
  });
  add('sentMail', {
    'type': 'Mail',
    'audience': 'teachers',
    'class': '',
    'title': 'Exam schedule',
    'content': 'The exam schedule has been published.',
    'date': d(-4),
    'time': '15:20',
    'recipients': '8',
    'segments': '0',
  });

  // ------------------------------------------------------------------ schedule
  const dayStarts = <String>['08:00', '08:55', '10:00', '10:55'];
  const dayEnds = <String>['08:45', '09:40', '10:45', '11:40'];
  for (var c = 0; c < classNames.length; c++) {
    for (var day = 0; day < 5; day++) {
      for (var p = 0; p < 4; p++) {
        add('schedule', {
          'class': classNames[c],
          'day': '$day',
          'subject': subjectNames[(c + day + p) % subjectNames.length],
          'start': dayStarts[p],
          'end': dayEnds[p],
        });
      }
    }
  }

  // --------------------------------------------------------------- attendance
  final attRnd = Random(42);
  final schoolDays = <DateTime>[];
  for (var back = 1; back <= 14 && schoolDays.length < 6; back++) {
    final day = addDays(base, -back);
    if (sundayIndex(day) <= 4) schoolDays.add(day); // Sunday..Thursday
  }
  for (final cls in classNames) {
    final students = s.studentsOfClass(cls);
    for (final day in schoolDays) {
      final map = <String, AttStatus>{};
      for (final st in students) {
        final r = attRnd.nextDouble();
        AttStatus status;
        if (r < 0.80) {
          status = AttStatus.present;
        } else if (r < 0.88) {
          status = AttStatus.late;
        } else if (r < 0.92) {
          status = AttStatus.lateExcuse;
        } else if (r < 0.97) {
          status = AttStatus.absent;
        } else {
          status = AttStatus.earlyDismissal;
        }
        map[st.id] = status;
      }
      s.attendance[s.attendanceKey(cls, iso(day))] = map;
    }
  }

  // --------------------------------------------------------------------- poll
  s.pollQuestion = 'Which day suits the parent-teacher meeting best?';
  s.pollOptions = <String>['Sunday', 'Tuesday', 'Thursday'];
  s.pollVotes = <int>[4, 7, 3];
}
