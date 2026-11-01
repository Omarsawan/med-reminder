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
///
/// Every row has a `dirty` flag: set by local changes, cleared once the change
/// is handed to sync. Changes that arrive from another phone are stored clean.
class Repository {
  Repository._(this._db);

  final Database _db;

  /// [path] is for tests; the app uses its standard database location.
  static Future<Repository> open({String? path}) async {
    path ??= p.join(await getDatabasesPath(), 'med_reminder.db');
    final db = await openDatabase(
      path,
      version: 2,
      onCreate: (db, _) async {
        for (final table in ['people', 'medicines']) {
          await db.execute('''
            CREATE TABLE $table (
              id TEXT PRIMARY KEY,
              data TEXT NOT NULL,
              updated_at INTEGER NOT NULL,
              deleted INTEGER NOT NULL DEFAULT 0,
              dirty INTEGER NOT NULL DEFAULT 1
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
            dirty INTEGER NOT NULL DEFAULT 1,
            UNIQUE (medicine_id, scheduled_at)
          )''');
        await db.execute('CREATE INDEX logs_by_time ON logs (scheduled_at)');
        await db.execute('CREATE TABLE settings (key TEXT PRIMARY KEY, value TEXT NOT NULL)');
      },
      onUpgrade: (db, from, _) async {
        if (from < 2) {
          // Sync support: everything existing counts as not yet synced, and a
          // dose's log id is derived from the dose so two phones marking the
          // same dose update the same record.
          for (final table in ['people', 'medicines', 'logs']) {
            await db.execute('ALTER TABLE $table ADD COLUMN dirty INTEGER NOT NULL DEFAULT 1');
          }
          await db.execute("UPDATE logs SET id = medicine_id || '_' || scheduled_at");
        }
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
          'id': logId(log.medicineId, log.scheduledAt),
          'medicine_id': log.medicineId,
          'scheduled_at': log.scheduledAt.millisecondsSinceEpoch,
          'status': log.status.name,
          'at': log.at.millisecondsSinceEpoch,
          'amount': log.amount,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
          'deleted': 0,
          'dirty': 1,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

  // Soft delete, so undoing a dose reaches the other phones too.
  Future<void> deleteLog(String id) => _db.update(
        'logs',
        {'deleted': 1, 'dirty': 1, 'updated_at': DateTime.now().millisecondsSinceEpoch},
        where: 'id = ?',
        whereArgs: [id],
      );

  /// One log per dose: the id comes from the medicine and the dose time.
  static String logId(String medicineId, DateTime scheduledAt) =>
      '${medicineId}_${scheduledAt.millisecondsSinceEpoch}';

  // Sync ----------------------------------------------------------------------

  /// Rows changed on this phone and not yet sent, including deletions.
  Future<List<SyncRow>> dirtyRows(String table) async {
    final rows = await _db.query(table, where: 'dirty = 1');
    return [for (final r in rows) SyncRow.fromRow(table, r)];
  }

  /// Marks a row sent, unless it changed again in the meantime.
  Future<void> markClean(String table, String id, int updatedAt) => _db.update(
        table,
        {'dirty': 0},
        where: 'id = ? AND updated_at = ?',
        whereArgs: [id, updatedAt],
      );

  /// Marks everything for sending, e.g. after joining a family.
  Future<void> markAllDirty() async {
    for (final table in ['people', 'medicines', 'logs']) {
      await _db.update(table, {'dirty': 1});
    }
  }

  /// Stores a change from another phone if it is newer than what's here.
  /// Returns whether anything changed.
  Future<bool> applyRemote(SyncRow row) async {
    final existing = await _db.query(
      row.table,
      columns: ['updated_at'],
      where: 'id = ?',
      whereArgs: [row.id],
    );
    if (existing.isNotEmpty && (existing.first['updated_at'] as int) >= row.updatedAt) {
      return false;
    }
    await _db.insert(row.table, row.toRow(), conflictAlgorithm: ConflictAlgorithm.replace);
    return true;
  }

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
          'dirty': 1,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

  // Soft delete, so sync can tell other phones about the deletion.
  Future<void> _deleteDoc(String table, String id) => _db.update(
        table,
        {'deleted': 1, 'dirty': 1, 'updated_at': DateTime.now().millisecondsSinceEpoch},
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

/// A row in the shape it is sent between phones.
class SyncRow {
  const SyncRow({
    required this.table,
    required this.id,
    required this.updatedAt,
    required this.deleted,
    required this.fields,
  });

  /// 'people', 'medicines' or 'logs'.
  final String table;
  final String id;
  final int updatedAt;
  final bool deleted;

  /// For people and medicines: `{'data': jsonString}`. For logs: the log
  /// columns.
  final Map<String, Object?> fields;

  static const _logFields = ['medicine_id', 'scheduled_at', 'status', 'at', 'amount'];

  factory SyncRow.fromRow(String table, Map<String, Object?> r) => SyncRow(
        table: table,
        id: r['id'] as String,
        updatedAt: r['updated_at'] as int,
        deleted: (r['deleted'] as int) == 1,
        fields: table == 'logs' ? {for (final f in _logFields) f: r[f]} : {'data': r['data']},
      );

  Map<String, Object?> toRow() => {
        'id': id,
        'updated_at': updatedAt,
        'deleted': deleted ? 1 : 0,
        'dirty': 0,
        ...fields,
      };
}
