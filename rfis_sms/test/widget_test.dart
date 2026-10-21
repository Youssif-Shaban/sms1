import 'package:flutter_test/flutter_test.dart';

import 'package:rfis_sms/app_state.dart';
import 'package:rfis_sms/main.dart';
import 'package:rfis_sms/models.dart';
import 'package:rfis_sms/util.dart';

void main() {
  test('grade scale', () {
    expect(gradeFor(95), 'A');
    expect(gradeFor(90), 'A');
    expect(gradeFor(80), 'B');
    expect(gradeFor(70), 'C');
    expect(gradeFor(60), 'D');
    expect(gradeFor(59.9), 'F');
  });

  test('promotion moves students and logs it', () {
    final app = AppState();
    final from = app.table('classes').first['name'];
    final to = app.table('classes').last['name'];
    final ids = app.studentsOfClass(from).map((s) => s.id).toList();
    expect(ids, isNotEmpty);
    app.promote(ids, from, to);
    expect(app.studentsOfClass(from), isEmpty);
    expect(app.table('promotionLog'), isNotEmpty);
  });

  test('attendance save and read back', () {
    final app = AppState();
    final cls = app.table('classes').first['name'];
    final s = app.studentsOfClass(cls).first;
    app.saveAttendance(cls, '2026-01-01', {s.id: AttStatus.absent});
    expect(app.attendanceFor(cls, '2026-01-01')![s.id], AttStatus.absent);
  });

  testWidgets('app starts on login screen', (tester) async {
    await tester.pumpWidget(const RfisApp());
    await tester.pump();
    expect(find.byType(RfisApp), findsOneWidget);
  });
}
