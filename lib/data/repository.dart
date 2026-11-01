import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../models/models.dart';

const _uuid = Uuid();
String newId() => _uuid.v4();

/// Local storage. People and medicines are stored as JSON documents so the
/// schema rarely needs migrating; logs get real columns because they are
/// queried by time.
class Repository {
  Repository._(this._db);

  final Database _db;

  static Future<Repository> open() async {
    final path = p.join(await getDatabasesPath(), 'med_reminder.db');
    final db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, _) async {
        for (final table in ['people', 'medicines']) {
          await db.execute('''
            CREATE TABLE $table (
              id TEXT PRIMARY KEY,
              data TEXT NOT NULL,
              updated_at INTEGER NOT NULL,
              deleted INTEGER NOT NULL DEFAULT 0
            )''');
        }
        await db.execute('''
          CREATE TABLE logs (
            id TEXT PRIMARY KEY,
            medicine_id TEXT NOT NULL,
            scheduled_at INTEGER NOT NULL,
            status TEXT NOT NULL,
            at INTEGER NOT NULL,
            amount REAL NOT NULL,
            updated_at INTEGER NOT NULL,
            deleted INTEGER NOT NULL DEFAULT 0,
            UNIQUE (medicine_id, scheduled_at)
          )''');
        await db.execute('CREATE INDEX logs_by_time ON logs (scheduled_at)');
        await db.execute('CREATE TABLE settings (key TEXT PRIMARY KEY, value TEXT NOT NULL)');
      },
    );
    return Repository._(db);
  }

  // People ------------------------------------------------------------------

  Future<List<Person>> people() async {
    final rows = await _db.query('people', where: 'deleted = 0');
    return [for (final r in rows) Person.fromJson(_decode(r))];
  }

  Future<void> savePerson(Person person) =>
      _saveDoc('people', person.id, person.toJson(), person.updatedAt);

  Future<void> deletePerson(String id) => _deleteDoc('people', id);

  // Medicines -----------------------------------------------------------------

  Future<List<Medicine>> medicines() async {
    final rows = await _db.query('medicines', where: 'deleted = 0');
    return [for (final r in rows) Medicine.fromJson(_decode(r))];
  }

  Future<void> saveMedicine(Medicine med) =>
      _saveDoc('medicines', med.id, med.toJson(), med.updatedAt);

  Future<void> deleteMedicine(String id) => _deleteDoc('medicines', id);

  // Logs ----------------------------------------------------------------------

  /// Logs whose scheduled time falls in [from, to).
  Future<List<DoseLog>> logsBetween(DateTime from, DateTime to) async {
    final rows = await _db.query(
      'logs',
      where: 'deleted = 0 AND scheduled_at >= ? AND scheduled_at < ?',
      whereArgs: [from.millisecondsSinceEpoch, to.millisecondsSinceEpoch],
      orderBy: 'scheduled_at',
    );
    return rows.map(_logFromRow).toList();
  }

  Future<DoseLog?> lastLogFor(String medicineId) async {
    final rows = await _db.query(
      'logs',
      where: 'deleted = 0 AND medicine_id = ? AND status = ?',
      whereArgs: [medicineId, LogStatus.taken.name],
      orderBy: 'scheduled_at DESC',
      limit: 1,
    );
    return rows.isEmpty ? null : _logFromRow(rows.first);
  }

  Future<void> saveLog(DoseLog log) => _db.insert(
        'logs',
        {
          'id': log.id,
          'medicine_id': log.medicineId,
          'scheduled_at': log.scheduledAt.millisecondsSinceEpoch,
          'status': log.status.name,
          'at': log.at.millisecondsSinceEpoch,
          'amount': log.amount,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
          'deleted': 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

  Future<void> deleteLog(String id) => _db.delete('logs', where: 'id = ?', whereArgs: [id]);

  // Settings ------------------------------------------------------------------

  Future<Map<String, dynamic>?> getJson(String key) async {
    final rows = await _db.query('settings', where: 'key = ?', whereArgs: [key]);
    if (rows.isEmpty) return null;
    return (jsonDecode(rows.first['value'] as String) as Map).cast<String, dynamic>();
  }

  Future<void> setJson(String key, Map<String, dynamic> value) => _db.insert(
        'settings',
        {'key': key, 'value': jsonEncode(value)},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

  // Helpers -------------------------------------------------------------------

  Future<void> _saveDoc(String table, String id, Map<String, dynamic> json, DateTime updatedAt) =>
      _db.insert(
        table,
        {
          'id': id,
          'data': jsonEncode(json),
          'updated_at': updatedAt.millisecondsSinceEpoch,
          'deleted': 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

  // Soft delete, so a future sync can tell other phones about the deletion.
  Future<void> _deleteDoc(String table, String id) => _db.update(
        table,
        {'deleted': 1, 'updated_at': DateTime.now().millisecondsSinceEpoch},
        where: 'id = ?',
        whereArgs: [id],
      );

  static Map<String, dynamic> _decode(Map<String, Object?> row) =>
      (jsonDecode(row['data'] as String) as Map).cast<String, dynamic>();

  static DoseLog _logFromRow(Map<String, Object?> r) => DoseLog(
        id: r['id'] as String,
        medicineId: r['medicine_id'] as String,
        scheduledAt: DateTime.fromMillisecondsSinceEpoch(r['scheduled_at'] as int),
        status: LogStatus.values.byName(r['status'] as String),
        at: DateTime.fromMillisecondsSinceEpoch(r['at'] as int),
        amount: (r['amount'] as num).toDouble(),
      );
}
