import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../util.dart';
import '../widgets/common.dart';
import '../widgets/crud.dart';
import 'assignment_submissions_screen.dart';
import 'exam_screens.dart';
import 'schedule_screen.dart';

const List<Opt> _genderOpts = [
  Opt('Male', 'ذكر', 'Male'),
  Opt('Female', 'أنثى', 'Female'),
];

const List<Opt> _statusOpts = [
  Opt('Active', 'نشط', 'Active'),
  Opt('Inactive', 'غير نشط', 'Inactive'),
];

const List<Opt> _fileTypeOpts = [
  Opt('PPTX', 'عرض PPTX', 'PPTX'),
  Opt('PDF', 'ملف PDF', 'PDF'),
  Opt('DOCX', 'مستند DOCX', 'DOCX'),
  Opt('XLSX', 'جدول XLSX', 'XLSX'),
  Opt('Video', 'فيديو', 'Video'),
  Opt('Link', 'رابط', 'Link'),
];

const List<Opt> _mediaTypeOpts = [
  Opt('Image', 'صورة', 'Image'),
  Opt('Video', 'فيديو', 'Video'),
  Opt('Audio', 'صوت', 'Audio'),
  Opt('Document', 'مستند', 'Document'),
];

IconData _fileIcon(String type) {
  switch (type) {
    case 'PPTX':
      return Icons.slideshow_outlined;
    case 'PDF':
      return Icons.picture_as_pdf_outlined;
    case 'DOCX':
      return Icons.description_outlined;
    case 'XLSX':
      return Icons.table_chart_outlined;
    case 'Video':
      return Icons.videocam_outlined;
    case 'Link':
      return Icons.link;
    case 'Image':
      return Icons.image_outlined;
    case 'Audio':
      return Icons.audiotrack_outlined;
    default:
      return Icons.insert_drive_file_outlined;
  }
}

// -------------------------------------------------------------------- people

Widget employeesScreen() {
  return CrudScreen(
    config: CrudConfig(
      table: 'employees',
      titleAr: 'الموظفون',
      titleEn: 'Employees',
      icon: Icons.badge_outlined,
      titleKey: 'name',
      subtitleKeys: const ['role', 'email'],
      filterKey: 'role',
      fields: const [
        FieldDef('code', 'رمز المستخدم', 'User code', required: true),
        FieldDef('name', 'الاسم الكامل', 'Full name', required: true),
        FieldDef('gender', 'الجنس', 'Gender',
            type: FieldType.choice, options: _genderOpts, required: true),
        FieldDef('role', 'الوظيفة', 'Role',
            type: FieldType.choice,
            required: true,
            options: [
              Opt('Teacher', 'معلم', 'Teacher'),
              Opt('Administrator', 'إداري', 'Administrator'),
              Opt('Librarian', 'أمين مكتبة', 'Librarian'),
            ]),
        FieldDef('email', 'البريد الإلكتروني', 'Email address',
            type: FieldType.email, required: true),
        FieldDef('phone', 'رقم الجوال', 'Mobile No', type: FieldType.phone),
        FieldDef('joined', 'تاريخ التعيين', 'Join date', type: FieldType.date),
      ],
    ),
  );
}

Widget coordinatorsScreen() {
  return CrudScreen(
    config: CrudConfig(
      table: 'coordinators',
      titleAr: 'المنسقون',
      titleEn: 'Coordinators',
      icon: Icons.supervisor_account_outlined,
      titleKey: 'name',
      subtitleKeys: const ['section', 'status'],
      filterKey: 'status',
      fields: const [
        FieldDef('name', 'الاسم', 'Name', required: true),
        FieldDef('section', 'القسم', 'Section',
            type: FieldType.choice,
            required: true,
            options: [
              Opt('Primary', 'الابتدائي', 'Primary'),
              Opt('Middle', 'المتوسط', 'Middle'),
              Opt('Secondary', 'الثانوي', 'Secondary'),
              Opt('Activities', 'الأنشطة', 'Activities'),
            ]),
        FieldDef('email', 'البريد الإلكتروني', 'Email address',
            type: FieldType.email, required: true),
        FieldDef('phone', 'رقم الجوال', 'Mobile No', type: FieldType.phone),
        FieldDef('status', 'الحالة', 'Status',
            type: FieldType.choice, options: _statusOpts, required: true),
      ],
    ),
  );
}

Widget studentsScreen() {
  return CrudScreen(
    config: CrudConfig(
      table: 'students',
      titleAr: 'الطلاب',
      titleEn: 'Students',
      icon: Icons.school_outlined,
      titleKey: 'name',
      subtitleKeys: const ['code', 'class'],
      filterKey: 'class',
      fields: const [
        FieldDef('code', 'رمز الطالب (تلقائي إن ترك فارغاً)', 'Student code (auto if empty)'),
        FieldDef('name', 'الاسم الكامل', 'Full name', required: true),
        FieldDef('gender', 'الجنس', 'Gender',
            type: FieldType.choice, options: _genderOpts, required: true),
        FieldDef('birthday', 'تاريخ الميلاد', 'Birthday', type: FieldType.date),
        FieldDef('class', 'الفصل', 'Class',
            type: FieldType.ref, refTable: 'classes', required: true),
        FieldDef('category', 'الفئة', 'Category',
            type: FieldType.ref, refTable: 'categories'),
        FieldDef('parent', 'ولي الأمر', 'Parent'),
        FieldDef('phone', 'رقم الجوال', 'Mobile No', type: FieldType.phone),
        FieldDef('email', 'البريد الإلكتروني', 'Email address',
            type: FieldType.email),
        FieldDef('address', 'العنوان', 'Address'),
        FieldDef('status', 'الحالة', 'Status',
            type: FieldType.choice, options: _statusOpts),
      ],
      onCreate: (app, data) {
        final out = <String, String>{...data};
        if ((out['code'] ?? '').isEmpty) out['code'] = app.nextStudentCode();
        if ((out['status'] ?? '').isEmpty) out['status'] = 'Active';
        return out;
      },
      actions: [
        RowAction(
          ar: 'الدرجات',
          en: 'Marks',
          icon: Icons.grading_outlined,
          onTap: (ctx, rec) {
            final app = ctx.app;
            app.marksheetStudentId = rec.id;
            app.marksheetExamId = null;
            app.marksheetTab = 1;
            app.go('marksheet');
          },
        ),
      ],
    ),
  );
}

Widget categoriesScreen() {
  return CrudScreen(
    config: CrudConfig(
      table: 'categories',
      titleAr: 'فئات الطلاب',
      titleEn: 'Student categories',
      icon: Icons.category_outlined,
      titleKey: 'name',
      subtitleKeys: const ['description'],
      fields: const [
        FieldDef('name', 'اسم الفئة', 'Category name', required: true),
        FieldDef('description', 'الوصف', 'Description', type: FieldType.multiline),
      ],
      trailing: (app, rec) =>
          '${app.table('students').where((s) => s['category'] == rec['name']).length}',
    ),
  );
}

/// Admission applications: add an application, then approve it to create the
/// student (and the parent when new) or reject it.
Widget admissionScreen() {
  return CrudScreen(
    config: CrudConfig(
      table: 'admissions',
      titleAr: 'طلبات القبول',
      titleEn: 'Admission applications',
      icon: Icons.person_add_alt_outlined,
      titleKey: 'name',
      subtitleKeys: const ['class', 'status', 'studentCode'],
      filterKey: 'status',
      fields: const [
        FieldDef('name', 'اسم الطالب', 'Student name', required: true),
        FieldDef('gender', 'الجنس', 'Gender',
            type: FieldType.choice, options: _genderOpts, required: true),
        FieldDef('birthday', 'تاريخ الميلاد', 'Birthday',
            type: FieldType.date, required: true),
        FieldDef('class', 'الفصل المطلوب', 'Requested class',
            type: FieldType.ref, refTable: 'classes', required: true),
        FieldDef('category', 'الفئة', 'Category',
            type: FieldType.ref, refTable: 'categories'),
        FieldDef('parent', 'ولي الأمر', 'Parent name', required: true),
        FieldDef('phone', 'رقم الجوال', 'Mobile No',
            type: FieldType.phone, required: true),
        FieldDef('email', 'البريد الإلكتروني', 'Email address',
            type: FieldType.email),
        FieldDef('address', 'العنوان', 'Address'),
        FieldDef('previousSchool', 'المدرسة السابقة', 'Previous school'),
      ],
      onCreate: (app, data) => <String, String>{
        ...data,
        'status': 'Pending',
        'date': iso(today()),
        'studentCode': '',
      },
      trailing: (app, rec) => rec['status'],
      actions: [
        RowAction(
          ar: 'قبول',
          en: 'Approve',
          icon: Icons.check_circle_outline,
          onTap: (ctx, rec) {
            final app = ctx.app;
            if (rec['status'] != 'Pending') {
              snack(ctx, ctx.tr('تمت معالجة هذا الطلب مسبقاً', 'This application was already processed'));
              return;
            }
            final student = app.approveAdmission(rec.id);
            if (student != null) {
              final code = student['code'];
              snack(ctx, ctx.tr('تم قبول الطالب برقم $code', 'Student admitted with code $code'));
            }
          },
        ),
        RowAction(
          ar: 'رفض',
          en: 'Reject',
          icon: Icons.cancel_outlined,
          onTap: (ctx, rec) {
            if (rec['status'] != 'Pending') {
              snack(ctx, ctx.tr('تمت معالجة هذا الطلب مسبقاً', 'This application was already processed'));
              return;
            }
            ctx.app.update('admissions', rec.id, {'status': 'Rejected'});
            snack(ctx, ctx.tr('تم رفض الطلب', 'Application rejected'));
          },
        ),
      ],
    ),
  );
}

// ------------------------------------------------------------------- classes

Widget classesScreen() {
  return CrudScreen(
    config: CrudConfig(
      table: 'classes',
      titleAr: 'الفصول',
      titleEn: 'Classes',
      icon: Icons.class_outlined,
      titleKey: 'name',
      subtitleKeys: const ['teacher', 'room'],
      fields: const [
        FieldDef('name', 'اسم الفصل', 'Class name', required: true),
        FieldDef('teacher', 'معلم الفصل', 'Class teacher',
            type: FieldType.ref, refTable: 'employees'),
        FieldDef('room', 'القاعة', 'Room'),
        FieldDef('description', 'الوصف', 'Description', type: FieldType.multiline),
      ],
      trailing: (app, rec) => '${app.studentsOfClass(rec['name']).length}',
      actions: [
        RowAction(
          ar: 'جدول الحصص',
          en: 'Schedule',
          icon: Icons.schedule,
          onTap: (ctx, rec) {
            Navigator.of(ctx).push(MaterialPageRoute<void>(
              builder: (_) => ClassScheduleScreen(className: rec['name']),
            ));
          },
        ),
      ],
    ),
  );
}

Widget subjectsScreen() {
  return CrudScreen(
    config: CrudConfig(
      table: 'subjects',
      titleAr: 'المواد',
      titleEn: 'Subjects',
      icon: Icons.subject_outlined,
      titleKey: 'name',
      subtitleKeys: const ['code', 'teacher'],
      fields: const [
        FieldDef('name', 'اسم المادة', 'Subject name', required: true),
        FieldDef('code', 'الرمز', 'Code'),
        FieldDef('teacher', 'المعلم', 'Teacher',
            type: FieldType.ref, refTable: 'employees'),
      ],
    ),
  );
}

// ------------------------------------------------------------ learning items

Widget materialsScreen() {
  return CrudScreen(
    config: CrudConfig(
      table: 'materials',
      titleAr: 'المواد الدراسية',
      titleEn: 'Study material',
      icon: Icons.menu_book_outlined,
      titleKey: 'title',
      subtitleKeys: const ['subject', 'class', 'date'],
      filterKey: 'subject',
      fields: const [
        FieldDef('title', 'العنوان', 'Title', required: true),
        FieldDef('subject', 'المادة', 'Subject',
            type: FieldType.ref, refTable: 'subjects', required: true),
        FieldDef('class', 'الفصل', 'Class',
            type: FieldType.ref, refTable: 'classes', required: true),
        FieldDef('fileType', 'نوع الملف', 'File type',
            type: FieldType.choice, options: _fileTypeOpts, required: true),
        FieldDef('date', 'التاريخ', 'Date', type: FieldType.date),
        FieldDef('description', 'الوصف', 'Description', type: FieldType.multiline),
      ],
      iconFor: (rec) => _fileIcon(rec['fileType']),
      trailing: (app, rec) => rec['fileType'],
      onCreate: (app, data) {
        final out = <String, String>{...data};
        if ((out['date'] ?? '').isEmpty) out['date'] = iso(today());
        out['sharedBy'] = app.profile['name'] ?? '';
        return out;
      },
      actions: [
        RowAction(
          ar: 'تنزيل',
          en: 'Download',
          icon: Icons.download_outlined,
          onTap: (ctx, rec) => snack(
            ctx,
            ctx.tr('جارٍ تنزيل "${rec['title']}" (محاكاة)', 'Downloading "${rec['title']}" (simulated)'),
          ),
        ),
      ],
    ),
  );
}

Widget mediaScreen() {
  return CrudScreen(
    config: CrudConfig(
      table: 'media',
      titleAr: 'مركز الوسائط',
      titleEn: 'Media center',
      icon: Icons.perm_media_outlined,
      titleKey: 'title',
      subtitleKeys: const ['type', 'album', 'date'],
      filterKey: 'type',
      fields: const [
        FieldDef('title', 'العنوان', 'Title', required: true),
        FieldDef('type', 'النوع', 'Type',
            type: FieldType.choice, options: _mediaTypeOpts, required: true),
        FieldDef('album', 'الألبوم', 'Album'),
        FieldDef('date', 'التاريخ', 'Date', type: FieldType.date),
        FieldDef('description', 'الوصف', 'Description', type: FieldType.multiline),
      ],
      iconFor: (rec) => _fileIcon(rec['type']),
      onCreate: (app, data) {
        final out = <String, String>{...data};
        if ((out['date'] ?? '').isEmpty) out['date'] = iso(today());
        return out;
      },
      actions: [
        RowAction(
          ar: 'عرض',
          en: 'View',
          icon: Icons.visibility_outlined,
          onTap: (ctx, rec) => snack(
            ctx,
            ctx.tr('فتح "${rec['title']}" (محاكاة)', 'Opening "${rec['title']}" (simulated)'),
          ),
        ),
      ],
    ),
  );
}

Widget examsScreen() {
  return CrudScreen(
    config: CrudConfig(
      table: 'exams',
      titleAr: 'قائمة الاختبارات',
      titleEn: 'Exams list',
      icon: Icons.quiz_outlined,
      titleKey: 'name',
      subtitleKeys: const ['class', 'subject', 'date'],
      filterKey: 'class',
      fields: const [
        FieldDef('name', 'اسم الاختبار', 'Exam name', required: true),
        FieldDef('class', 'الفصل', 'Class',
            type: FieldType.ref, refTable: 'classes', required: true),
        FieldDef('subject', 'المادة', 'Subject',
            type: FieldType.ref, refTable: 'subjects', required: true),
        FieldDef('date', 'تاريخ الاختبار', 'Exam date',
            type: FieldType.date, required: true),
        FieldDef('maxMark', 'الدرجة العظمى', 'Max mark',
            type: FieldType.number, required: true),
        FieldDef('duration', 'المدة (دقائق)', 'Duration (minutes)',
            type: FieldType.number),
        FieldDef('type', 'نوع الاختبار', 'Exam type',
            type: FieldType.choice,
            required: true,
            options: [
              Opt('Online', 'إلكتروني', 'Online'),
              Opt('Written', 'ورقي', 'Written'),
            ]),
        FieldDef('description', 'الوصف', 'Description', type: FieldType.multiline),
      ],
      validate: (data) {
        final max = double.tryParse(data['maxMark'] ?? '');
        if (max == null || max <= 0) {
          return 'الدرجة العظمى يجب أن تكون أكبر من صفر / Max mark must be greater than 0';
        }
        final dur = data['duration'] ?? '';
        if (dur.isNotEmpty && (double.tryParse(dur) ?? 0) <= 0) {
          return 'المدة يجب أن تكون أكبر من صفر / Duration must be greater than 0';
        }
        return null;
      },
      trailing: (app, rec) => rec['type'],
      actions: [
        RowAction(
          ar: 'الدرجات',
          en: 'Marks',
          icon: Icons.grading_outlined,
          onTap: (ctx, rec) {
            final app = ctx.app;
            app.marksheetExamId = rec.id;
            app.marksheetStudentId = null;
            app.marksheetTab = 0;
            app.go('marksheet');
          },
        ),
        RowAction(
          ar: 'الأسئلة',
          en: 'Questions',
          icon: Icons.question_answer_outlined,
          onTap: (ctx, rec) {
            if (rec['type'] != 'Online') {
              snack(ctx, ctx.tr('الأسئلة متاحة للاختبارات الإلكترونية فقط', 'Questions are only for online exams'));
              return;
            }
            Navigator.of(ctx).push(MaterialPageRoute<void>(
              builder: (_) => ExamQuestionsScreen(examId: rec.id),
            ));
          },
        ),
        RowAction(
          ar: 'بدء الاختبار',
          en: 'Take exam',
          icon: Icons.play_arrow,
          onTap: (ctx, rec) {
            if (rec['type'] != 'Online') {
              snack(ctx, ctx.tr('هذا اختبار ورقي', 'This is a written exam'));
              return;
            }
            Navigator.of(ctx).push(MaterialPageRoute<void>(
              builder: (_) => ExamTakeScreen(examId: rec.id),
            ));
          },
        ),
      ],
    ),
  );
}

Widget assignmentsScreen() {
  return CrudScreen(
    config: CrudConfig(
      table: 'assignments',
      titleAr: 'الواجبات الإلكترونية',
      titleEn: 'Online assignments',
      icon: Icons.assignment_outlined,
      titleKey: 'title',
      subtitleKeys: const ['class', 'subject', 'end'],
      filterKey: 'class',
      fields: const [
        FieldDef('title', 'عنوان الواجب', 'Assignment title', required: true),
        FieldDef('class', 'الفصل', 'Class',
            type: FieldType.ref, refTable: 'classes', required: true),
        FieldDef('subject', 'المادة', 'Subject',
            type: FieldType.ref, refTable: 'subjects', required: true),
        FieldDef('type', 'النوع', 'Type',
            type: FieldType.choice,
            required: true,
            options: [
              Opt('Assignment', 'واجب', 'Assignment'),
              Opt('Homework', 'واجب منزلي', 'Homework'),
            ]),
        FieldDef('start', 'تاريخ البداية', 'Start date',
            type: FieldType.date, required: true),
        FieldDef('end', 'الموعد النهائي', 'Assignment deadline',
            type: FieldType.date, required: true),
        FieldDef('description', 'الوصف', 'Description', type: FieldType.multiline),
        FieldDef('attachment', 'اسم الملف المرفق', 'Attachment file name'),
      ],
      validate: (data) {
        final s = parseIso(data['start'] ?? '');
        final e = parseIso(data['end'] ?? '');
        if (s != null && e != null && e.isBefore(s)) {
          return 'الموعد النهائي قبل تاريخ البداية / Deadline is before the start date';
        }
        return null;
      },
      trailing: (app, rec) =>
          '${app.submittedCount(rec.id)}/${app.studentsOfClass(rec['class']).length}',
      actions: [
        RowAction(
          ar: 'التسليمات',
          en: 'Submissions',
          icon: Icons.fact_check_outlined,
          onTap: (ctx, rec) {
            Navigator.of(ctx).push(MaterialPageRoute<void>(
              builder: (_) => AssignmentSubmissionsScreen(assignmentId: rec.id),
            ));
          },
        ),
      ],
    ),
  );
}

// ------------------------------------------------------------- communication

Widget templatesScreen() {
  return CrudScreen(
    config: CrudConfig(
      table: 'templates',
      titleAr: 'قوالب البريد / الرسائل',
      titleEn: 'Mail / SMS templates',
      icon: Icons.mark_email_read_outlined,
      titleKey: 'title',
      subtitleKeys: const ['type'],
      filterKey: 'type',
      fields: const [
        FieldDef('title', 'عنوان القالب', 'Template title', required: true),
        FieldDef('type', 'النوع', 'Type',
            type: FieldType.choice,
            required: true,
            options: [
              Opt('Mail', 'بريد إلكتروني', 'Mail'),
              Opt('SMS', 'رسالة نصية', 'SMS'),
            ]),
        FieldDef('content', 'المحتوى ({student} {class} {date} {school})',
            'Content ({student} {class} {date} {school})',
            type: FieldType.multiline, required: true),
      ],
    ),
  );
}

Widget notificationsScreen() {
  return CrudScreen(
    config: CrudConfig(
      table: 'notifications',
      titleAr: 'إشعارات الجوال',
      titleEn: 'Mobile notifications',
      icon: Icons.notifications_none,
      titleKey: 'title',
      subtitleKeys: const ['audience', 'date', 'time'],
      canEdit: false,
      fields: const [
        FieldDef('title', 'عنوان الإشعار', 'Notification title', required: true),
        FieldDef('message', 'نص الإشعار', 'Message',
            type: FieldType.multiline, required: true),
        FieldDef('audience', 'الفئة المستهدفة', 'Audience',
            type: FieldType.choice,
            required: true,
            options: [
              Opt('All', 'الجميع', 'Everyone'),
              Opt('Students', 'الطلاب', 'Students'),
              Opt('Teachers', 'المعلمون', 'Teachers'),
              Opt('Parents', 'أولياء الأمور', 'Parents'),
            ]),
      ],
      onCreate: (app, data) {
        final students = app.table('students').length;
        final teachers = app.teacherCount;
        final parents = app.table('parents').length;
        int recipients;
        switch (data['audience']) {
          case 'Students':
            recipients = students;
            break;
          case 'Teachers':
            recipients = teachers;
            break;
          case 'Parents':
            recipients = parents;
            break;
          default:
            recipients = students + teachers + parents;
        }
        return <String, String>{
          ...data,
          'recipients': '$recipients',
          'date': iso(today()),
          'time': nowTime(),
          'sentBy': app.profile['name'] ?? '',
        };
      },
      trailing: (app, rec) => '${rec['recipients']}',
    ),
  );
}
