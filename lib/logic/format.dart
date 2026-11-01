import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../models/models.dart';

/// Turns model values into display text in the current language.
class Fmt {
  Fmt(this.l) : locale = l.localeName;

  final AppLocalizations l;
  final String locale;

  bool get isArabic => locale.startsWith('ar');

  String time(DateTime t) => DateFormat.jm(locale).format(t);

  String doseTime(DoseTime t) => time(t.on(DateTime(2000)));

  String date(DateTime d) => DateFormat.MMMEd(locale).format(d);

  String longDate(DateTime d) => DateFormat.MMMMEEEEd(locale).format(d);

  /// 1 = Monday.
  String weekdayShort(int weekday) => DateFormat.E(locale).format(DateTime(2024, 1, weekday));

  /// 0.5 -> "½", 1.5 -> "1½", 2.0 -> "2".
  String number(double v) {
    final whole = v.truncate();
    final frac = v - whole;
    const fractions = [(0.25, '¼'), (0.5, '½'), (0.75, '¾')];
    for (final (value, symbol) in fractions) {
      if ((frac - value).abs() < 0.001) return whole == 0 ? symbol : '$whole$symbol';
    }
    if (frac.abs() < 0.001) return '$whole';
    return v.toStringAsFixed(1);
  }

  String amount(DoseUnit unit, double value) {
    final text = number(value);
    final isWhole = (value - value.truncate()).abs() < 0.001;
    // Pick the plural form: whole numbers use their own value; fractions use
    // the form each language uses for fractional amounts.
    final count = isWhole ? value.toInt() : (isArabic ? 100 : (value <= 1 ? 1 : 2));
    return switch (unit) {
      DoseUnit.tablet => l.unitTablet(count, text),
      DoseUnit.capsule => l.unitCapsule(count, text),
      DoseUnit.ml => l.unitMl(count, text),
      DoseUnit.drop => l.unitDrop(count, text),
      DoseUnit.puff => l.unitPuff(count, text),
      DoseUnit.unit => l.unitUnit(count, text),
      DoseUnit.sachet => l.unitSachet(count, text),
      DoseUnit.application => l.unitApplication(count, text),
    };
  }

  String unitName(DoseUnit unit) => switch (unit) {
        DoseUnit.tablet => l.nameTablet,
        DoseUnit.capsule => l.nameCapsule,
        DoseUnit.ml => l.nameMl,
        DoseUnit.drop => l.nameDrop,
        DoseUnit.puff => l.namePuff,
        DoseUnit.unit => l.nameUnit,
        DoseUnit.sachet => l.nameSachet,
        DoseUnit.application => l.nameApplication,
      };

  String instruction(Instruction i) => switch (i) {
        Instruction.none => l.instrNone,
        Instruction.beforeFood => l.instrBeforeFood,
        Instruction.withFood => l.instrWithFood,
        Instruction.afterFood => l.instrAfterFood,
        Instruction.emptyStomach => l.instrEmptyStomach,
        Instruction.bedtime => l.instrBedtime,
      };

  /// "1 tablet · After food"
  String doseLine(Medicine m) {
    final parts = [amount(m.unit, m.amount)];
    if (m.instruction != Instruction.none) parts.add(instruction(m.instruction));
    return parts.join(' · ');
  }

  String schedule(Medicine m, DateTime now) {
    final s = m.schedule;
    final base = switch (s.type) {
      ScheduleType.daily => '${l.scheduleDaily} · ${s.times.map(doseTime).join(', ')}',
      ScheduleType.weekdays =>
        '${(s.weekdays.toList()..sort()).map(weekdayShort).join(', ')} · ${s.times.map(doseTime).join(', ')}',
      ScheduleType.interval =>
        l.everyHoursFrom(l.everyHours(s.intervalHours), doseTime(s.intervalStart)),
      ScheduleType.asNeeded => l.asNeededSummary(number(s.minGapHours)),
      ScheduleType.everyNDays => _everyNDays(s, now),
    };
    final end = s.endDate;
    if (end == null || s.isFinished(now)) return base;
    final left = daysBetween(now, end) + 1;
    return '$base · ${l.daysLeft(left)}';
  }

  /// "Every 30 days · 9:00 AM · next Sat, Nov 28"
  String _everyNDays(Schedule s, DateTime now) {
    final parts = [l.everyDays(s.intervalDays), s.times.map(doseTime).join(', ')];
    final next = s.occurrences(now, now.add(Duration(days: s.intervalDays + 1))).firstOrNull;
    if (next != null) parts.add(l.nextDoseOn(date(next)));
    return parts.join(' · ');
  }
}
