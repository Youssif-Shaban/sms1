import 'package:flutter/material.dart';

import '../app_state.dart';
import 'account_screen.dart';
import 'attendance_screens.dart';
import 'calendar_screen.dart';
import 'dashboard_screen.dart';
import 'mail_sms_screen.dart';
import 'marksheet_screen.dart';
import 'messages_screen.dart';
import 'module_screens.dart';
import 'promotion_screen.dart';

class NavItem {
  const NavItem(this.route, this.ar, this.en, this.icon,
      [this.children = const <NavItem>[]]);

  final String route;
  final String ar;
  final String en;
  final IconData icon;
  final List<NavItem> children;
}

/// Same menu structure as the portal sidebar.
const List<NavItem> kNav = [
  NavItem('dashboard', 'لوحة التحكم', 'Dashboard', Icons.dashboard_outlined),
  NavItem('coordinators', 'المنسقون', 'Coordinators',
      Icons.supervisor_account_outlined),
  NavItem('messages', 'الرسائل', 'Messages', Icons.mail_outline),
  NavItem('mailsms', 'بريد / رسائل نصية', 'Mail / SMS', Icons.sms_outlined),
  NavItem('mobileNotif', 'إشعارات الجوال', 'Mobile Notifications',
      Icons.notifications_none),
  NavItem('calender', 'التقويم', 'Calendar', Icons.calendar_month_outlined),
  NavItem('attendanceGroup', 'الحضور', 'Attendance', Icons.fact_check_outlined, [
    NavItem('attendance', 'تسجيل الحضور', 'Take attendance',
        Icons.how_to_reg_outlined),
    NavItem('attendance_report', 'تقرير الحضور', 'Attendance report',
        Icons.assessment_outlined),
  ]),
  NavItem('media', 'مركز الوسائط', 'Media Center', Icons.perm_media_outlined),
  NavItem('teachers', 'الموظفون', 'Employees', Icons.badge_outlined),
  NavItem('studentsGroup', 'الطلاب', 'Students', Icons.school_outlined, [
    NavItem('students', 'قائمة الطلاب', 'Students list', Icons.groups_outlined),
    NavItem('admission', 'طلبات القبول', 'Admission',
        Icons.person_add_alt_outlined),
    NavItem('categories', 'فئات الطلاب', 'Categories', Icons.category_outlined),
    NavItem('marksheet', 'كشف الدرجات', 'Marksheet', Icons.grading_outlined),
  ]),
  NavItem('materials', 'المواد الدراسية', 'Study Material',
      Icons.menu_book_outlined),
  NavItem('examsList', 'قائمة الاختبارات', 'Exams List', Icons.quiz_outlined),
  NavItem('onlineAssignments', 'الواجبات الإلكترونية', 'Online Assignments',
      Icons.assignment_outlined),
  NavItem('classesGroup', 'الفصول', 'Classes', Icons.class_outlined, [
    NavItem('classes', 'قائمة الفصول', 'Classes list', Icons.class_outlined),
    NavItem('subjects', 'المواد', 'Subjects', Icons.subject_outlined),
  ]),
  NavItem('adminGroup', 'المهام الإدارية', 'Administrative tasks',
      Icons.admin_panel_settings_outlined, [
    NavItem('promotion', 'ترقية الطلاب', 'Promotion', Icons.trending_up),
    NavItem('mailsmsTemplates', 'قوالب البريد / الرسائل',
        'Mail / SMS templates', Icons.mark_email_read_outlined),
  ]),
];

NavItem? findNav(String route, [List<NavItem> items = kNav]) {
  for (final item in items) {
    if (item.route == route) return item;
    final child = findNav(route, item.children);
    if (child != null) return child;
  }
  return null;
}

String screenTitle(BuildContext context, String route) {
  if (route == 'account') return context.tr('إعدادات الحساب', 'Account settings');
  if (route == 'terms') return context.tr('شروط المدرسة', 'School terms');
  final item = findNav(route);
  return item == null ? 'RFIS' : context.tr(item.ar, item.en);
}

Widget screenFor(String route) {
  switch (route) {
    case 'dashboard':
      return const DashboardScreen();
    case 'coordinators':
      return coordinatorsScreen();
    case 'messages':
      return const MessagesScreen();
    case 'mailsms':
      return const MailSmsScreen();
    case 'mobileNotif':
      return notificationsScreen();
    case 'calender':
      return const CalendarScreen();
    case 'attendance':
      return const AttendanceScreen();
    case 'attendance_report':
      return const AttendanceReportScreen();
    case 'media':
      return mediaScreen();
    case 'teachers':
      return employeesScreen();
    case 'students':
      return studentsScreen();
    case 'admission':
      return admissionScreen();
    case 'categories':
      return categoriesScreen();
    case 'marksheet':
      return const MarksheetScreen();
    case 'materials':
      return materialsScreen();
    case 'examsList':
      return examsScreen();
    case 'onlineAssignments':
      return assignmentsScreen();
    case 'classes':
      return classesScreen();
    case 'subjects':
      return subjectsScreen();
    case 'promotion':
      return const PromotionScreen();
    case 'mailsmsTemplates':
      return templatesScreen();
    case 'account':
      return const AccountScreen();
    case 'terms':
      return const TermsScreen();
    default:
      return const DashboardScreen();
  }
}

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    return Scaffold(
      appBar: AppBar(
        title: Text(screenTitle(context, app.route)),
        actions: [
          IconButton(
            tooltip: context.tr('English', 'العربية'),
            icon: const Icon(Icons.translate),
            onPressed: () => app.setLanguage(!app.isArabic),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle_outlined),
            onSelected: (value) {
              if (value == 'messages') app.go('messages');
              if (value == 'account') app.go('account');
              if (value == 'logout') {
                Navigator.of(context).popUntil((r) => r.isFirst);
                app.logout();
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem<String>(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app.profile['name'] ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      app.profile['email'] ?? '',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem<String>(
                value: 'messages',
                child: Text(ctx.tr('الرسائل', 'Messages')),
              ),
              PopupMenuItem<String>(
                value: 'account',
                child: Text(ctx.tr('إعدادات الحساب', 'Account Settings')),
              ),
              PopupMenuItem<String>(
                value: 'logout',
                child: Text(ctx.tr('تسجيل الخروج', 'Logout')),
              ),
            ],
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: KeyedSubtree(
        key: ValueKey<String>(app.route),
        child: screenFor(app.route),
      ),
    );
  }
}

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  Widget _tile(BuildContext context, AppState app, NavItem item,
      {bool nested = false}) {
    final label = context.tr(item.ar, item.en);
    if (item.children.isEmpty) {
      return ListTile(
        contentPadding: EdgeInsetsDirectional.only(start: nested ? 40 : 16, end: 16),
        leading: Icon(item.icon),
        title: Text(label),
        selected: app.route == item.route,
        trailing: item.route == 'messages' && app.unreadMessages > 0
            ? Badge(label: Text('${app.unreadMessages}'))
            : null,
        onTap: () {
          Navigator.of(context).pop();
          app.go(item.route);
        },
      );
    }
    final open = item.children.any((c) => c.route == app.route);
    return ExpansionTile(
      initiallyExpanded: open,
      leading: Icon(item.icon),
      title: Text(label),
      children: [
        for (final child in item.children)
          _tile(context, app, child, nested: true),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: const Color(0xFF3E7C3E),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.school, color: Colors.white, size: 36),
                  const SizedBox(height: 8),
                  const Text(
                    'RFIS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    context.tr('نظام إدارة المدرسة (محاكاة)', 'School management system (simulation)'),
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  for (final item in kNav) _tile(context, app, item),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.gavel_outlined),
              title: Text(context.tr('شروط المدرسة', 'School Terms')),
              selected: app.route == 'terms',
              onTap: () {
                Navigator.of(context).pop();
                app.go('terms');
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: Text(context.tr('تسجيل الخروج', 'Logout')),
              onTap: () {
                Navigator.of(context).popUntil((r) => r.isFirst);
                app.logout();
              },
            ),
          ],
        ),
      ),
    );
  }
}
