import '../data/repository.dart';
import '../models/models.dart';
import '../models/settings.dart';

/// The app's core operations. Used both by the UI and by the notification
/// buttons, which may run while the app is closed.
class MedService {
  MedService(this.repo);

  final Repository repo;

  Future<AppSettings> settings() async => AppSettings.fromJson(await repo.getJson('settings'));

  Future<void> saveSettings(AppSettings s) => repo.setJson('settings', s.toJson());

  /// Scheduled doses of active medicines in [from, to), with their logs.
  Future<List<Dose>> dosesBetween(DateTime from, DateTime to) async {
    final meds = (await repo.medicines()).where((m) => m.active && !m.isAsNeeded);
    final logs = await repo.logsBetween(from, to);
    final byKey = {for (final l in logs) _key(l.medicineId, l.scheduledAt): l};
    final doses = <Dose>[
      for (final m in meds)
        for (final t in m.schedule.occurrences(from, to))
          if (!t.isBefore(m.firstDoseFrom)) Dose(medicine: m, at: t, log: byKey[_key(m.id, t)]),
    ];
    doses.sort((a, b) {
      final byTime = a.at.compareTo(b.at);
      return byTime != 0 ? byTime : a.medicine.name.compareTo(b.medicine.name);
    });
    return doses;
  }

  Future<void> mark(Dose dose, LogStatus status) async {
    if (dose.log?.status == status) return;
    if (dose.log != null) await undo(dose);
    final med = await _freshMedicine(dose.medicine.id) ?? dose.medicine;
    final amount = status == LogStatus.taken ? med.amount : 0.0;
    await repo.saveLog(DoseLog(
      id: Repository.logId(med.id, dose.at),
      medicineId: med.id,
      scheduledAt: dose.at,
      status: status,
      at: DateTime.now(),
      amount: amount,
    ));
    await _adjustStock(med, -amount);
  }

  Future<void> undo(Dose dose) async {
    final log = dose.log;
    if (log == null) return;
    await repo.deleteLog(log.id);
    final med = await _freshMedicine(dose.medicine.id);
    if (med != null) await _adjustStock(med, log.amount);
  }

  /// Marks every still-pending dose at [slot] as taken. Returns how many.
  Future<int> markSlotTaken(DateTime slot) async {
    final doses = await dosesBetween(slot, slot.add(const Duration(minutes: 1)));
    final pending = doses.where((d) => d.isPending).toList();
    for (final d in pending) {
      await mark(d, LogStatus.taken);
    }
    return pending.length;
  }

  Future<void> takeAsNeeded(Medicine med) async {
    final now = DateTime.now();
    await repo.saveLog(DoseLog(
      id: Repository.logId(med.id, now),
      medicineId: med.id,
      scheduledAt: now,
      status: LogStatus.taken,
      at: now,
      amount: med.amount,
    ));
    await _adjustStock(med, -med.amount);
  }

  /// As-needed doses taken today, newest first.
  Future<List<DoseLog>> asNeededLogsToday(Medicine med) async {
    final today = dateOnly(DateTime.now());
    final logs = await repo.logsBetween(today, today.add(const Duration(days: 1)));
    return logs.where((l) => l.medicineId == med.id).toList().reversed.toList();
  }

  // Snoozes: slot time (ms) -> remind-again time (ms).

  Future<Map<int, int>> snoozes() async {
    final raw = await repo.getJson('snoozes') ?? {};
    final cutoff = DateTime.now().subtract(const Duration(days: 1)).millisecondsSinceEpoch;
    return {
      for (final e in raw.entries)
        if (int.parse(e.key) > cutoff) int.parse(e.key): e.value as int,
    };
  }

  Future<void> snooze(DateTime slot, DateTime until) async {
    final s = await snoozes();
    s[slot.millisecondsSinceEpoch] = until.millisecondsSinceEpoch;
    await repo.setJson('snoozes', {for (final e in s.entries) '${e.key}': e.value});
  }

  Future<Medicine?> _freshMedicine(String id) async {
    for (final m in await repo.medicines()) {
      if (m.id == id) return m;
    }
    return null;
  }

  Future<void> _adjustStock(Medicine med, double delta) async {
    if (med.stock == null || delta == 0) return;
    final next = (med.stock! + delta).clamp(0, double.infinity).toDouble();
    await repo.saveMedicine(med.copyWith(stock: () => next));
  }

  static String _key(String medicineId, DateTime at) => '$medicineId|${at.millisecondsSinceEpoch}';
}
