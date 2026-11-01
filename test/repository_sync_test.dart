import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:med_reminder/data/repository.dart';
import 'package:med_reminder/models/models.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Repository repo;
  var n = 0;
  setUp(() async => repo = await Repository.open(path: 'file:sync_test_${n++}?mode=memory&cache=shared'));

  final at = DateTime(2026, 11, 2, 8);
  DoseLog log(LogStatus status) => DoseLog(
        id: 'ignored',
        medicineId: 'med1',
        scheduledAt: at,
        status: status,
        at: at,
        amount: 1,
      );

  Person person(String name, DateTime updatedAt) =>
      Person(id: 'p1', name: name, color: 0xFF000000, updatedAt: updatedAt);

  test('local changes are dirty until marked clean', () async {
    await repo.savePerson(person('Mom', DateTime(2026, 11, 1)));
    final dirty = await repo.dirtyRows('people');
    expect(dirty.single.id, 'p1');
    await repo.markClean('people', 'p1', dirty.single.updatedAt);
    expect(await repo.dirtyRows('people'), isEmpty);
  });

  test('a change made while sending stays dirty', () async {
    await repo.savePerson(person('Mom', DateTime(2026, 11, 1)));
    final sent = (await repo.dirtyRows('people')).single;
    await repo.savePerson(person('Mama', DateTime(2026, 11, 2)));
    await repo.markClean('people', 'p1', sent.updatedAt);
    expect((await repo.dirtyRows('people')).single.updatedAt, DateTime(2026, 11, 2).millisecondsSinceEpoch);
  });

  test('the newest change wins, whichever phone made it', () async {
    await repo.savePerson(person('Mom', DateTime(2026, 11, 2)));
    final older = SyncRow(
      table: 'people',
      id: 'p1',
      updatedAt: DateTime(2026, 11, 1).millisecondsSinceEpoch,
      deleted: false,
      fields: {'data': '{"id":"p1","name":"Old","color":0,"updatedAt":"2026-11-01T00:00:00.000"}'},
    );
    expect(await repo.applyRemote(older), isFalse);
    expect((await repo.people()).single.name, 'Mom');

    final newer = SyncRow(
      table: 'people',
      id: 'p1',
      updatedAt: DateTime(2026, 11, 3).millisecondsSinceEpoch,
      deleted: false,
      fields: {'data': '{"id":"p1","name":"New","color":0,"updatedAt":"2026-11-03T00:00:00.000"}'},
    );
    expect(await repo.applyRemote(newer), isTrue);
    expect((await repo.people()).single.name, 'New');
    // Remote changes don't bounce back to the server.
    expect(await repo.dirtyRows('people'), isEmpty);
  });

  test('a remote deletion removes the record', () async {
    await repo.savePerson(person('Mom', DateTime(2026, 11, 1)));
    final row = (await repo.dirtyRows('people')).single;
    await repo.applyRemote(SyncRow(
      table: 'people',
      id: 'p1',
      updatedAt: row.updatedAt + 1,
      deleted: true,
      fields: row.fields,
    ));
    expect(await repo.people(), isEmpty);
  });

  test('marking the same dose twice keeps one record', () async {
    await repo.saveLog(log(LogStatus.skipped));
    await repo.saveLog(log(LogStatus.taken));
    final logs = await repo.logsBetween(at, at.add(const Duration(minutes: 1)));
    expect(logs.single.status, LogStatus.taken);
    expect(logs.single.id, Repository.logId('med1', at));
  });

  test('undoing a dose is sent as a deletion', () async {
    await repo.saveLog(log(LogStatus.taken));
    final id = Repository.logId('med1', at);
    final sent = (await repo.dirtyRows('logs')).single;
    await repo.markClean('logs', id, sent.updatedAt);

    await repo.deleteLog(id);
    expect(await repo.logsBetween(at, at.add(const Duration(minutes: 1))), isEmpty);
    final deletion = (await repo.dirtyRows('logs')).single;
    expect(deletion.deleted, isTrue);
    expect(deletion.fields['medicine_id'], 'med1');
  });

  test('upgrading a phase 1 database keeps data and queues it for sharing', () async {
    final dir = await Directory.systemTemp.createTemp('med_reminder_upgrade');
    final path = '${dir.path}/v1.db';
    // The phase 1 schema, as already installed on the family's phones.
    final v1 = await databaseFactoryFfi.openDatabase(path,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, _) async {
            for (final table in ['people', 'medicines']) {
              await db.execute('CREATE TABLE $table (id TEXT PRIMARY KEY, data TEXT NOT NULL, '
                  'updated_at INTEGER NOT NULL, deleted INTEGER NOT NULL DEFAULT 0)');
            }
            await db.execute('CREATE TABLE logs (id TEXT PRIMARY KEY, medicine_id TEXT NOT NULL, '
                'scheduled_at INTEGER NOT NULL, status TEXT NOT NULL, at INTEGER NOT NULL, amount REAL NOT NULL, '
                'updated_at INTEGER NOT NULL, deleted INTEGER NOT NULL DEFAULT 0, UNIQUE (medicine_id, scheduled_at))');
            await db.execute('CREATE TABLE settings (key TEXT PRIMARY KEY, value TEXT NOT NULL)');
          },
        ));
    await v1.insert('logs', {
      'id': 'a-random-uuid',
      'medicine_id': 'med1',
      'scheduled_at': at.millisecondsSinceEpoch,
      'status': 'taken',
      'at': at.millisecondsSinceEpoch,
      'amount': 1.0,
      'updated_at': at.millisecondsSinceEpoch,
    });
    await v1.close();

    final upgraded = await Repository.open(path: path);
    final logs = await upgraded.logsBetween(at, at.add(const Duration(minutes: 1)));
    expect(logs.single.id, Repository.logId('med1', at));
    expect(logs.single.status, LogStatus.taken);
    expect((await upgraded.dirtyRows('logs')).single.id, Repository.logId('med1', at));
    await dir.delete(recursive: true);
  });

  test('a dose marked on another phone shows up here', () async {
    final applied = await repo.applyRemote(SyncRow(
      table: 'logs',
      id: Repository.logId('med1', at),
      updatedAt: DateTime(2026, 11, 2, 8, 5).millisecondsSinceEpoch,
      deleted: false,
      fields: {
        'medicine_id': 'med1',
        'scheduled_at': at.millisecondsSinceEpoch,
        'status': 'taken',
        'at': DateTime(2026, 11, 2, 8, 5).millisecondsSinceEpoch,
        'amount': 1.0,
      },
    ));
    expect(applied, isTrue);
    expect((await repo.logsBetween(at, at.add(const Duration(minutes: 1)))).single.status, LogStatus.taken);
  });
}
