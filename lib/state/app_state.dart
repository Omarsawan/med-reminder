import 'package:flutter/foundation.dart';

import '../data/repository.dart';
import '../logic/env.dart';
import '../models/models.dart';
import '../models/settings.dart';

/// What the screens show, reloaded from the database after every change.
class AppState extends ChangeNotifier {
  AppState(this.env);

  final Env env;

  List<Person> people = [];
  List<Medicine> medicines = [];
  AppSettings settings = const AppSettings();
  List<Dose> today = [];

  /// As-needed medicines and their doses taken today.
  Map<String, List<DoseLog>> asNeededToday = {};
  final Map<String, DoseLog?> _lastAsNeeded = {};

  Person? personById(String id) {
    for (final p in people) {
      if (p.id == id) return p;
    }
    return null;
  }

  Medicine? medicineById(String id) {
    for (final m in medicines) {
      if (m.id == id) return m;
    }
    return null;
  }

  DoseLog? lastAsNeededDose(String medicineId) => _lastAsNeeded[medicineId];

  List<Medicine> get lowStock =>
      medicines.where((m) => m.active && m.isLowStock && !m.schedule.isFinished(DateTime.now())).toList();

  Future<void> load() async {
    final svc = env.service;
    settings = await svc.settings();
    people = await env.repo.people()
      ..sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
    medicines = await env.repo.medicines()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final start = dateOnly(DateTime.now());
    today = await svc.dosesBetween(start, start.add(const Duration(days: 1)));
    asNeededToday = {};
    _lastAsNeeded.clear();
    for (final m in medicines.where((m) => m.active && m.isAsNeeded)) {
      asNeededToday[m.id] = await svc.asNeededLogsToday(m);
      _lastAsNeeded[m.id] = await env.repo.lastLogFor(m.id);
    }
    notifyListeners();
  }

  /// Reloads the screens and hands the new schedule to the OS.
  Future<void> _changed() async {
    await load();
    await env.reminders.rescheduleAll();
  }

  /// Called when the app comes back to the foreground.
  Future<void> refresh() => _changed();

  Future<void> saveSettings(AppSettings s) async {
    await env.service.saveSettings(s);
    if (s.language != settings.language) {
      // Notification buttons on iOS are registered with their labels.
      await env.reminders.initialize();
    }
    await _changed();
  }

  // People --------------------------------------------------------------------

  Future<Person> addPerson(String name, int color) async {
    final p = Person(id: newId(), name: name.trim(), color: color, updatedAt: DateTime.now());
    await env.repo.savePerson(p);
    await load();
    return p;
  }

  Future<void> savePerson(Person p) async {
    await env.repo.savePerson(p);
    await _changed();
  }

  /// Returns false when the person still has medicines.
  Future<bool> deletePerson(Person p) async {
    if (medicines.any((m) => m.personId == p.id)) return false;
    await env.repo.deletePerson(p.id);
    await load();
    return true;
  }

  // Medicines -------------------------------------------------------------------

  Future<void> saveMedicine(Medicine m) async {
    final old = medicineById(m.id);
    if (old?.photo != null && old!.photo != m.photo) await env.photos.remove(old.photo);
    await env.repo.saveMedicine(m);
    await _changed();
  }

  Future<void> deleteMedicine(Medicine m) async {
    await env.photos.remove(m.photo);
    await env.repo.deleteMedicine(m.id);
    await _changed();
  }

  // Doses ---------------------------------------------------------------------

  Future<void> mark(Dose dose, LogStatus status) async {
    await env.service.mark(dose, status);
    await env.reminders.clearSlotIfDone(dose.at);
    await _changed();
  }

  Future<void> undo(Dose dose) async {
    await env.service.undo(dose);
    await _changed();
  }

  Future<void> markSlotTaken(DateTime slot) async {
    await env.service.markSlotTaken(slot);
    await env.reminders.clearSlot(slot);
    await _changed();
  }

  Future<void> takeAsNeeded(Medicine m) async {
    await env.service.takeAsNeeded(m);
    await _changed();
  }

  Future<void> undoAsNeeded(DoseLog log) async {
    final m = medicineById(log.medicineId);
    if (m == null) return;
    await env.service.undo(Dose(medicine: m, at: log.scheduledAt, log: log));
    await _changed();
  }
}
