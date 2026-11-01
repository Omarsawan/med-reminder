/// A clock time without a date, e.g. 08:30.
class DoseTime implements Comparable<DoseTime> {
  const DoseTime(this.hour, this.minute);

  final int hour;
  final int minute;

  int get minutesOfDay => hour * 60 + minute;

  DateTime on(DateTime day) => DateTime(day.year, day.month, day.day, hour, minute);

  static DoseTime parse(String s) {
    final parts = s.split(':');
    return DoseTime(int.parse(parts[0]), int.parse(parts[1]));
  }

  @override
  String toString() =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  @override
  int compareTo(DoseTime other) => minutesOfDay.compareTo(other.minutesOfDay);

  @override
  bool operator ==(Object other) =>
      other is DoseTime && other.hour == hour && other.minute == minute;

  @override
  int get hashCode => minutesOfDay;
}

enum ScheduleType { daily, interval, weekdays, asNeeded, everyNDays }

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Whole calendar days from [a] to [b], unaffected by daylight-saving shifts.
int daysBetween(DateTime a, DateTime b) =>
    DateTime.utc(b.year, b.month, b.day).difference(DateTime.utc(a.year, a.month, a.day)).inDays;

/// When a medicine should be taken. Pure data, so it can be stored as JSON and
/// later synced between phones unchanged.
class Schedule {
  const Schedule({
    required this.type,
    this.times = const [],
    this.weekdays = const {},
    this.intervalDays = 30,
    this.intervalHours = 8,
    this.intervalStart = const DoseTime(8, 0),
    this.minGapHours = 4,
    this.maxPerDay,
    required this.startDate,
    this.durationDays,
  });

  final ScheduleType type;

  /// Clock times for [ScheduleType.daily], [ScheduleType.weekdays] and
  /// [ScheduleType.everyNDays].
  final List<DoseTime> times;

  /// Days for [ScheduleType.weekdays], using [DateTime.weekday] (1 = Monday).
  final Set<int> weekdays;

  /// For [ScheduleType.everyNDays]: doses on [startDate] and every
  /// [intervalDays] days after it, e.g. 30 for a monthly injection.
  final int intervalDays;

  /// For [ScheduleType.interval]: a dose every [intervalHours], the first one at
  /// [intervalStart] on [startDate].
  final int intervalHours;
  final DoseTime intervalStart;

  /// For [ScheduleType.asNeeded].
  final double minGapHours;
  final int? maxPerDay;

  final DateTime startDate;

  /// Null means ongoing; otherwise the course lasts this many days including
  /// [startDate].
  final int? durationDays;

  /// Last day of the course, or null if ongoing.
  DateTime? get endDate => durationDays == null
      ? null
      : DateTime(startDate.year, startDate.month, startDate.day + durationDays! - 1);

  bool isFinished(DateTime now) {
    final end = endDate;
    return end != null && dateOnly(now).isAfter(end);
  }

  /// All scheduled dose times in [from, to). As-needed medicines have none.
  List<DateTime> occurrences(DateTime from, DateTime to) {
    final result = <DateTime>[];
    if (!to.isAfter(from)) return result;
    final start = dateOnly(startDate);
    final end = endDate;

    switch (type) {
      case ScheduleType.asNeeded:
        return result;
      case ScheduleType.interval:
        if (intervalHours <= 0) return result;
        final anchor = intervalStart.on(start);
        final step = Duration(hours: intervalHours);
        final limit = end == null
            ? to
            : _min(to, DateTime(end.year, end.month, end.day + 1));
        var k = 0;
        if (from.isAfter(anchor)) {
          k = from.difference(anchor).inMinutes ~/ step.inMinutes;
        }
        while (true) {
          final t = anchor.add(step * k);
          if (!t.isBefore(limit)) break;
          if (!t.isBefore(from)) result.add(t);
          k++;
        }
        return result;
      case ScheduleType.daily:
      case ScheduleType.weekdays:
      case ScheduleType.everyNDays:
        final sorted = [...times]..sort();
        var day = _max(dateOnly(from), start);
        final lastDay = end == null ? dateOnly(to) : _min(dateOnly(to), end);
        while (!day.isAfter(lastDay)) {
          final included = switch (type) {
            ScheduleType.weekdays => weekdays.contains(day.weekday),
            ScheduleType.everyNDays => intervalDays > 0 && daysBetween(start, day) % intervalDays == 0,
            _ => true,
          };
          if (included) {
            for (final time in sorted) {
              final t = time.on(day);
              if (!t.isBefore(from) && t.isBefore(to)) result.add(t);
            }
          }
          day = DateTime(day.year, day.month, day.day + 1);
        }
        return result;
    }
  }

  /// The first dose at or after [from], or null if there is none within a
  /// year (as-needed, or a finished course). Looks in widening windows so
  /// daily schedules don't compute a year of doses.
  DateTime? nextAfter(DateTime from) {
    for (final days in const [2, 32, 400]) {
      final found = occurrences(from, from.add(Duration(days: days)));
      if (found.isNotEmpty) return found.first;
    }
    return null;
  }

  Schedule copyWith({
    ScheduleType? type,
    List<DoseTime>? times,
    Set<int>? weekdays,
    int? intervalDays,
    int? intervalHours,
    DoseTime? intervalStart,
    double? minGapHours,
    int? Function()? maxPerDay,
    DateTime? startDate,
    int? Function()? durationDays,
  }) =>
      Schedule(
        type: type ?? this.type,
        times: times ?? this.times,
        weekdays: weekdays ?? this.weekdays,
        intervalDays: intervalDays ?? this.intervalDays,
        intervalHours: intervalHours ?? this.intervalHours,
        intervalStart: intervalStart ?? this.intervalStart,
        minGapHours: minGapHours ?? this.minGapHours,
        maxPerDay: maxPerDay != null ? maxPerDay() : this.maxPerDay,
        startDate: startDate ?? this.startDate,
        durationDays: durationDays != null ? durationDays() : this.durationDays,
      );

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'times': times.map((t) => t.toString()).toList(),
        'weekdays': weekdays.toList()..sort(),
        'intervalDays': intervalDays,
        'intervalHours': intervalHours,
        'intervalStart': intervalStart.toString(),
        'minGapHours': minGapHours,
        'maxPerDay': maxPerDay,
        'startDate': _dateString(startDate),
        'durationDays': durationDays,
      };

  factory Schedule.fromJson(Map<String, dynamic> j) => Schedule(
        type: ScheduleType.values.byName(j['type'] as String),
        times: [for (final t in j['times'] as List) DoseTime.parse(t as String)],
        weekdays: {for (final d in j['weekdays'] as List) d as int},
        intervalDays: j['intervalDays'] as int? ?? 30,
        intervalHours: j['intervalHours'] as int,
        intervalStart: DoseTime.parse(j['intervalStart'] as String),
        minGapHours: (j['minGapHours'] as num).toDouble(),
        maxPerDay: j['maxPerDay'] as int?,
        startDate: DateTime.parse(j['startDate'] as String),
        durationDays: j['durationDays'] as int?,
      );
}

String _dateString(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime _min(DateTime a, DateTime b) => a.isBefore(b) ? a : b;
DateTime _max(DateTime a, DateTime b) => a.isAfter(b) ? a : b;
