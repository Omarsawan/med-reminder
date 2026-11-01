import 'package:flutter_test/flutter_test.dart';
import 'package:med_reminder/models/models.dart';

void main() {
  final monday = DateTime(2026, 11, 2);

  group('daily', () {
    final s = Schedule(
      type: ScheduleType.daily,
      times: const [DoseTime(20, 0), DoseTime(8, 0)],
      startDate: monday,
    );

    test('lists each time every day, in order', () {
      final t = s.occurrences(monday, monday.add(const Duration(days: 2)));
      expect(t, [
        DateTime(2026, 11, 2, 8),
        DateTime(2026, 11, 2, 20),
        DateTime(2026, 11, 3, 8),
        DateTime(2026, 11, 3, 20),
      ]);
    });

    test('nothing before the start date', () {
      final t = s.occurrences(monday.subtract(const Duration(days: 3)), monday.add(const Duration(hours: 12)));
      expect(t, [DateTime(2026, 11, 2, 8)]);
    });

    test('range is start-inclusive, end-exclusive', () {
      final at8 = DateTime(2026, 11, 2, 8);
      expect(s.occurrences(at8, at8.add(const Duration(minutes: 1))), [at8]);
      expect(s.occurrences(at8.subtract(const Duration(hours: 1)), at8), isEmpty);
    });
  });

  test('a 3-day course stops after the third day', () {
    final s = Schedule(
      type: ScheduleType.daily,
      times: const [DoseTime(9, 0)],
      startDate: monday,
      durationDays: 3,
    );
    final t = s.occurrences(monday, monday.add(const Duration(days: 10)));
    expect(t.length, 3);
    expect(t.last, DateTime(2026, 11, 4, 9));
    expect(s.isFinished(DateTime(2026, 11, 4, 23)), isFalse);
    expect(s.isFinished(DateTime(2026, 11, 5)), isTrue);
  });

  test('weekdays only on the chosen days', () {
    final s = Schedule(
      type: ScheduleType.weekdays,
      times: const [DoseTime(9, 30)],
      weekdays: const {DateTime.monday, DateTime.thursday},
      startDate: monday,
    );
    final t = s.occurrences(monday, monday.add(const Duration(days: 14)));
    expect(t.map((d) => d.weekday).toSet(), {DateTime.monday, DateTime.thursday});
    expect(t.length, 4);
  });

  group('every N hours', () {
    final s = Schedule(
      type: ScheduleType.interval,
      intervalHours: 8,
      intervalStart: const DoseTime(6, 0),
      startDate: monday,
    );

    test('continues across days from the first dose', () {
      final t = s.occurrences(monday, monday.add(const Duration(days: 2)));
      expect(t.take(4), [
        DateTime(2026, 11, 2, 6),
        DateTime(2026, 11, 2, 14),
        DateTime(2026, 11, 2, 22),
        DateTime(2026, 11, 3, 6),
      ]);
      expect(t.length, 6);
    });

    test('a window starting mid-way finds the next dose', () {
      final from = DateTime(2026, 11, 5, 15);
      expect(s.occurrences(from, from.add(const Duration(hours: 8))), [DateTime(2026, 11, 5, 22)]);
    });

    test('hours that do not divide a day carry over to the next day', () {
      final s10 = s.copyWith(intervalHours: 10);
      final t = s10.occurrences(monday, monday.add(const Duration(days: 1)));
      expect(t, [DateTime(2026, 11, 2, 6), DateTime(2026, 11, 2, 16)]);
      final next = s10.occurrences(monday.add(const Duration(days: 1)), monday.add(const Duration(days: 2)));
      expect(next.first, DateTime(2026, 11, 3, 2));
    });
  });

  group('every N days', () {
    final s = Schedule(
      type: ScheduleType.everyNDays,
      intervalDays: 30,
      times: const [DoseTime(9, 0)],
      startDate: monday,
    );

    test('every 30 days from the start date', () {
      final t = s.occurrences(monday, DateTime(2027, 2, 1));
      expect(t, [
        DateTime(2026, 11, 2, 9),
        DateTime(2026, 12, 2, 9),
        DateTime(2027, 1, 1, 9),
        DateTime(2027, 1, 31, 9),
      ]);
    });

    test('nothing in between', () {
      expect(s.occurrences(DateTime(2026, 11, 3), DateTime(2026, 12, 2)), isEmpty);
    });

    test('every other day', () {
      final t = s.copyWith(intervalDays: 2).occurrences(monday, monday.add(const Duration(days: 6)));
      expect(t.map((d) => d.day), [2, 4, 6]);
    });

    test('older saved schedules without the field default to 30 days', () {
      final json = s.toJson()..remove('intervalDays');
      expect(Schedule.fromJson(json).intervalDays, 30);
    });
  });

  group('next dose', () {
    test('later today for a daily medicine', () {
      final s = Schedule(type: ScheduleType.daily, times: const [DoseTime(8, 0), DoseTime(20, 0)], startDate: monday);
      expect(s.nextAfter(DateTime(2026, 11, 2, 9)), DateTime(2026, 11, 2, 20));
    });

    test('weeks away for a monthly injection', () {
      final s = Schedule(
        type: ScheduleType.everyNDays,
        intervalDays: 30,
        times: const [DoseTime(17, 0)],
        startDate: DateTime(2026, 10, 19),
      );
      expect(s.nextAfter(DateTime(2026, 11, 1, 14)), DateTime(2026, 11, 18, 17));
    });

    test('none once a course is over, or for as-needed', () {
      final course = Schedule(type: ScheduleType.daily, times: const [DoseTime(9, 0)], startDate: monday, durationDays: 2);
      expect(course.nextAfter(DateTime(2026, 11, 5)), isNull);
      expect(Schedule(type: ScheduleType.asNeeded, startDate: monday).nextAfter(monday), isNull);
    });
  });

  test('as-needed medicines have no scheduled doses', () {
    final s = Schedule(type: ScheduleType.asNeeded, startDate: monday);
    expect(s.occurrences(monday, monday.add(const Duration(days: 7))), isEmpty);
  });

  test('schedule survives a JSON round trip', () {
    final s = Schedule(
      type: ScheduleType.weekdays,
      times: const [DoseTime(7, 5)],
      weekdays: const {2, 5},
      maxPerDay: 3,
      startDate: monday,
      durationDays: 10,
    );
    expect(Schedule.fromJson(s.toJson()).toJson(), s.toJson());
  });

  group('medicine', () {
    final med = Medicine(
      id: 'm',
      personId: 'p',
      name: 'Test',
      unit: DoseUnit.tablet,
      amount: 1,
      schedule: Schedule(type: ScheduleType.daily, times: const [DoseTime(8, 0)], startDate: monday),
      updatedAt: DateTime(2026, 11, 2, 15),
      stock: 12,
    );
    final at = DateTime(2026, 11, 2, 8);
    final dose = Dose(medicine: med, at: at);

    test('upcoming, due within two hours, then missed', () {
      expect(dose.stateAt(at.subtract(const Duration(minutes: 1))), DoseState.upcoming);
      expect(dose.stateAt(at.add(const Duration(minutes: 90))), DoseState.due);
      expect(dose.stateAt(at.add(const Duration(hours: 3))), DoseState.missed);
    });

    test('a logged dose reports its log', () {
      final taken = Dose(
        medicine: med,
        at: at,
        log: DoseLog(id: 'l', medicineId: 'm', scheduledAt: at, status: LogStatus.taken, at: at, amount: 1),
      );
      expect(taken.stateAt(at.add(const Duration(hours: 5))), DoseState.taken);
    });

    test('JSON round trip keeps creation time and stock', () {
      final back = Medicine.fromJson(med.toJson());
      expect(back.createdAt, med.createdAt);
      expect(back.stock, 12);
      expect(back.firstDoseFrom, DateTime(2026, 11, 2, 14));
    });
  });
}
